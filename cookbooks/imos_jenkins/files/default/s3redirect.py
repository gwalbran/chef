#!/usr/bin/env python

import argparse
import datetime
import os
import sys
from collections import OrderedDict
from urlparse import urlparse


def alert(text):
    print("{0}{1}".format(text, os.linesep))


try:
    import boto
except ImportError:
    alert("Please install boto. `pip install boto`")
    sys.exit(os.EX_UNAVAILABLE)

try:
    import xmltodict
except ImportError:
    alert("Please install xmltodict. `pip install xmltodict`")
    sys.exit(os.EX_UNAVAILABLE)


def get_core_keys(conf):
    """Get key names for suffix and error_key (i.e. index and error pages for S3 website)

    :param conf:
    :return: tuple containing suffix and error_key values
    """
    try:
        suffix = conf.get('WebsiteConfiguration').get('IndexDocument').get('Suffix')
    except AttributeError:
        suffix = u'index.html'
    try:
        error_key = conf.get('WebsiteConfiguration').get('ErrorDocument').get('Key')
    except AttributeError:
        error_key = u'error.html'
    return suffix, error_key


def get_routes(conf):
    """Return sorted list of routes from website config dictionary. Guaranteed to return a valid list regardless of
        input being empty, singular or multiple rules

    :param conf:
    :return: sorted list of OrderedDict routing rules
    """
    try:
        routes = conf.get('WebsiteConfiguration').get('RoutingRules').get('RoutingRule')
        if isinstance(routes, OrderedDict):
            routes = [routes]
    except AttributeError:
        routes = list()
    return routes


def get_index_html(bucket, rules, fqdn):
    """Return HTML string containing formatted table of all existing rules

    :param bucket: S3 bucket name
    :param rules: S4 routing rules dict
    :param fqdn: fully qualified domain name of S3 website
    :return: string containing HTML of all rules found in rules object
    """
    rows = list()
    for rule in rules:
        prefix = rule.condition.key_prefix
        redirect = rule.redirect.replace_key or rule.redirect.replace_key_prefix
        rows.append("""            <tr>
            <td><a href="http://{0}/{1}">{1}</a></td>
            <td><a href="http://{0}/{2}">{2}</a></td>
            <td>{3}</td>
        </tr>""".format(fqdn, prefix, redirect, str(rule.redirect.replace_key_prefix is None)))

    html = """<!DOCTYPE html>
    <html lang="en">
        <head>
            <meta content="text/html;charset=utf-8" http-equiv="Content-Type">
            <title>Latest artifacts: {0}</title>
            <style type="text/css">
                body{{font-family:Arial,sans-serif;background:#428bca;}}
                h1,h2{{color:#fff;text-shadow: 1px 1px 1px #000000;}}
                a{{text-decoration:none;color:#444;}}
                table{{width:100%;border-spacing:0;}}
                th{{background:#215b8d;color: #fff;}}
                td{{background:#fff;border-bottom: 1px solid #aaa;}}
                th,td{{padding:15px;text-align: left;}}
            </style>
        </head>
        <body>
            <h1>Latest artifacts: <a href="http://{3}">{0}</a></h1>
            <table>
                <tr><th>Prefix</th><th>Redirect</th><th>Absolute?</th></tr>
    {1}
            </table>
            <h2>Generated at: {2}</h2>
        </body>
    </html>""".format(bucket, os.linesep.join(rows), datetime.datetime.now(), fqdn)
    return html


def main():
    # define command-line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("bucket", help="Which bucket to put the redirect in", type=str)
    parser.add_argument("key", help="The key to redirect", type=str)
    parser.add_argument("uri", help="The URI to redirect to", type=str)
    parser.add_argument('-a', '--access-key', help="AWS Access Key ID. Environment variable: AWS_ACCESS_KEY", type=str)
    parser.add_argument('-s', '--access-secret', help="AWS Access Key Secret. Environment variable: AWS_SECRET_KEY",
                        type=str)
    parser.add_argument('-u', '--update', help="Update an existing S3 key", action="store_true", default=False)
    parser.add_argument('-o', '--output-file', help="Name of the HTML output file", type=str)

    # handle command-line arguments and read AWS from either command-line or environment variables
    args = parser.parse_args()
    aws_key = args.access_key
    aws_secret = args.access_secret

    output_file = args.output_file

    # lookup AWS key environment variables
    if aws_key is None:
        aws_key = os.environ.get('AWS_ACCESS_KEY')
    if aws_secret is None:
        aws_secret = os.environ.get('AWS_SECRET_KEY')

    if aws_key is None or aws_secret is None:
        alert('Unable to find AWS credentials.')
        parser.print_help()
        sys.exit(os.EX_NOINPUT)

    # connect to S3 and test connection
    s3connection = boto.connect_s3(aws_key, aws_secret)
    try:
        s3bucket = s3connection.get_bucket(args.bucket)
    except boto.exception.S3ResponseError:
        alert("Bucket '{0}' could not be retrieved with the specified credentials".format(args.bucket))
        sys.exit(os.EX_NOINPUT)

    # if *not* running with 'update' flag, check for an existing key first before exiting with error due to existing key
    s3key = s3bucket.get_key(args.key)
    if s3key is not None and not args.update:
        alert("Key '{0}' is already in use. Please use the --update option to use this key anyway.".format(args.key))
        sys.exit(os.EX_UNAVAILABLE)

    # retrieve website configuration
    try:
        raw_config = s3bucket.get_website_configuration_with_xml()
        website_config = xmltodict.parse(raw_config[1])
        website_fqdn = s3bucket.get_website_endpoint()
    except boto.exception.S3ResponseError:
        website_config = dict()
        website_fqdn = str()

    if website_config:  # if this bucket is a website, use the RedirectRules to handle the redirect
        suffix, error_key = get_core_keys(website_config)
        routes = get_routes(website_config)

        # new rules object to populate existing
        rules = boto.s3.website.RoutingRules()

        for route in routes:
            prefix = route.get('Condition').get('KeyPrefixEquals')
            if prefix == args.key and not args.update:
                alert(
                    "There is already a redirect for '{0}'. Please use the --update option to use this key anyway.".format(
                        args.key))
                sys.exit(os.EX_UNAVAILABLE)
            elif not prefix == args.key:
                # must handle rules being either absolute (ReplaceKeyWith) or relative (ReplaceKeyPrefixWith)
                if 'ReplaceKeyWith' in route.get('Redirect'):
                    rules.add_rule(boto.s3.website.RoutingRule.when(key_prefix=prefix).then_redirect(
                        hostname=route.get('Redirect').get('HostName'), protocol=route.get('Redirect').get('Protocol'),
                        replace_key=route.get('Redirect').get('ReplaceKeyWith')))
                elif 'ReplaceKeyPrefixWith' in route.get('Redirect'):
                    rules.add_rule(boto.s3.website.RoutingRule.when(key_prefix=prefix).then_redirect(
                        hostname=route.get('Redirect').get('HostName'), protocol=route.get('Redirect').get('Protocol'),
                        replace_key_prefix=route.get('Redirect').get('ReplaceKeyPrefixWith')))

        uri = urlparse(args.uri)
        path = uri.path or None
        if uri.query:
            path = "{0}?{1}".format(path, uri.query)
        rules.add_rule(boto.s3.website.RoutingRule.when(
            key_prefix=args.key).then_redirect(hostname=uri.netloc or None,
                                               protocol=uri.scheme or None,
                                               replace_key_prefix=path.lstrip(
                                                   '/')))
        # sort the rules alphabetically
        rules.sort(key=lambda r: r.condition.key_prefix)

        if s3bucket.configure_website(suffix=suffix, error_key=error_key, routing_rules=rules):
            if args.output_file:
                html = get_index_html(s3bucket.name, rules, website_fqdn)
                try:
                    s3output = s3bucket.new_key(output_file)
                    s3output.metadata = {'Content-Type': 'text/html'}
                    s3output.set_contents_from_string(html)
                except boto.exception.S3ResponseError as e:
                    alert("There was an error when updating the output file '{0}' in bucket. Error was: {1}".format(
                        output_file, str(e)))
                else:
                    alert('HTML index has been generated at {0}/{1}'.format(args.bucket, output_file))

            alert("{0}/{1} has been redirected to {2}".format(args.bucket, args.key.lstrip('/'), args.uri))
            sys.exit(os.EX_OK)
        else:
            alert('There was an error updating the redirect rules.')
            sys.exit(os.EX_UNAVAILABLE)
    else:  # This bucket isn't a website so we'll have to make a key
        s3key = s3bucket.new_key(args.key)
        s3key.set_redirect(args.uri)
        s3key.set_acl('public-read')

        alert("{0}/{1} has been redirected to {2}".format(args.bucket, args.key.lstrip('/'), args.uri))
        sys.exit(os.EX_OK)


if __name__ == '__main__':
    main()
