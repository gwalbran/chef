#!/usr/bin/env python

import os
import sys
import argparse

from urlparse import urlparse


def alert(text):
    sys.stdout.write(text + '\n')
    sys.stdout.flush()


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


# TODO: this has more or less retained the lack of structure of the original script, so could be improved by splitting
#       out this giant main() function a bit
def main():
    parser = argparse.ArgumentParser()

    parser.add_argument("bucket", help="Which bucket to put the redirect in", type=str)
    parser.add_argument("key", help="The key to redirect", type=str)
    parser.add_argument("uri", help="The URI to redirect to", type=str)

    parser.add_argument('-a', '--access-key', help="AWS Access Key ID. Environment variable: AWS_ACCESS_KEY", type=str)
    parser.add_argument('-s', '--access-secret', help="AWS Access Key Secret. Environment variable: AWS_SECRET_KEY",
                        type=str)
    parser.add_argument('-u', '--update', help="Update an existing S3 key", action="store_true", default=False)

    args = parser.parse_args()
    AWS_KEY = args.access_key
    AWS_SECRET = args.access_secret

    # lookup global AWS keys if needed
    if AWS_KEY is None:
        AWS_KEY = boto.config.get('Credentials', 'aws_access_key_id')

    if AWS_SECRET is None:
        AWS_SECRET = boto.config.get('Credentials', 'aws_secret_access_key')

    # lookup AWS key environment variables
    if AWS_KEY is None:
        AWS_KEY = os.environ.get('AWS_ACCESS_KEY')
    if AWS_SECRET is None:
        AWS_SECRET = os.environ.get('AWS_SECRET_KEY')

    if AWS_KEY is None or AWS_SECRET is None:
        alert('Unable to find AWS credentials.')
        parser.print_help()
        sys.exit(os.EX_NOINPUT)

    s3connection = boto.connect_s3(AWS_KEY, AWS_SECRET)

    # test the bucket connection
    try:
        s3bucket = s3connection.get_bucket(args.bucket)
    except boto.exception.S3ResponseError:
        alert('Bucket "%s" could not be retrieved with the specified credentials' % args.bucket)
        sys.exit(os.EX_NOINPUT)

    # check for an existing key first since that's cheaper
    s3key = s3bucket.get_key(args.key)
    if s3key is not None and not args.update:
        alert('Key "%s" is already in use. Please use the --update option to use this key anyway.' % args.key)
        sys.exit(os.EX_UNAVAILABLE)

    try:
        website_config = s3bucket.get_website_configuration_with_xml()
        config = xmltodict.parse(website_config[1])
    except boto.exception.S3ResponseError:
        config = False
    if config:  # if this bucket is a website, use the RedirectRules to handle the redirect
        try:
            suffix = config.get('WebsiteConfiguration').get('IndexDocument').get('Suffix')
        except AttributeError:
            suffix = u'index.html'
        try:
            error_key = config.get('WebsiteConfiguration').get('ErrorDocument').get('Key')
        except AttributeError:
            error_key = u'error.html'

        rules = boto.s3.website.RoutingRules()

        try:
            routes = config.get('WebsiteConfiguration').get('RoutingRules').get('RoutingRule')
        except AttributeError:
            routes = []

        for route in routes:
            prefix = route.get('Condition').get('KeyPrefixEquals')
            if prefix == args.key and not args.update:
                alert(
                    'There is already a redirect for "%s". Please use the --update option to use this key anyway.' %
                    args.key)
                sys.exit(os.EX_UNAVAILABLE)
            elif not prefix == args.key:
                if 'ReplaceKeyWith' in route.get('Redirect'):
                    # redirect all sub-folder requests to specific path
                    rules.add_rule(boto.s3.website.RoutingRule.when(key_prefix=prefix).then_redirect(
                        hostname=route.get('Redirect').get('HostName'), protocol=route.get('Redirect').get('Protocol'),
                        replace_key=route.get('Redirect').get('ReplaceKeyWith')))
                elif 'ReplaceKeyPrefixWith' in route.get('Redirect'):
                    # redirect requests with relative sub-folder, replacing prefix only
                    rules.add_rule(boto.s3.website.RoutingRule.when(key_prefix=prefix).then_redirect(
                        hostname=route.get('Redirect').get('HostName'), protocol=route.get('Redirect').get('Protocol'),
                        replace_key_prefix=route.get('Redirect').get('ReplaceKeyPrefixWith')))

        uri = urlparse(args.uri)
        path = uri.path or None
        if uri.query:
            path = path + '?' + uri.query
        rules.add_rule(boto.s3.website.RoutingRule.when(key_prefix=args.key).then_redirect(hostname=uri.netloc or None,
                                                                                           protocol=uri.scheme or None,
                                                                                           replace_key_prefix=path.lstrip(
                                                                                               '/')))

        if s3bucket.configure_website(suffix=suffix, error_key=error_key, routing_rules=rules):
            alert('%s/%s has been redirected to %s' % (args.bucket, args.key.lstrip('/'), args.uri))
            sys.exit(os.EX_OK)
        else:
            alert('There was an error updating the redirect rules.')
            sys.exit(os.EX_UNAVAILABLE)
    else:  # This bucket isn't a website so we'll have to make a key
        s3key = s3bucket.new_key(args.key)
        s3key.set_redirect(args.uri)
        s3key.set_acl('public-read')

        alert('%s/%s has been redirected to %s' % (args.bucket, args.key.lstrip('/'), args.uri))
        sys.exit(os.EX_OK)

if __name__ == '__main__':
    main()
