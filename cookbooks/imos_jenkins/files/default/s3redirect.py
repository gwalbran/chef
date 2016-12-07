import datetime
import os

import boto3
import click
from botocore.exceptions import ClientError

WEBSITE_SUFFIX = 's3-website-ap-southeast-2.amazonaws.com'


class ErrorCodes(object):
    nobucketaccess = 1
    keyexists = 2
    websiteconfigerror = 3


def exit_error(msg, code):
    print(msg)
    click.get_current_context().exit(code)


def test_bucket(client, bucket):
    try:
        client.head_bucket(Bucket=bucket)
    except ClientError:
        return False
    else:
        return True


def test_key_available(client, key, bucket):
    try:
        client.head_object(Key=key, Bucket=bucket)
    except ClientError as e:
        if e.response['ResponseMetadata']['HTTPStatusCode'] != 404:
            raise
        return True
    else:
        return False


def get_website_config(client, bucket):
    response = client.get_bucket_website(Bucket=bucket)
    return response


def put_website_config(client, bucket, config):
    client.put_bucket_website(Bucket=bucket, WebsiteConfiguration=config)


def put_website_index(client, bucket, output_file, content):
    client.put_object(Bucket=bucket, Key=output_file, Body=content, ContentType='text/html')


def get_index_html(bucket, rules, fqdn):
    rows = list()
    for rule in rules:
        prefix = rule['Condition']['KeyPrefixEquals']
        redirect = rule['Redirect'].get('ReplaceKeyPrefixWith') or rule['Redirect'].get('ReplaceKeyWith')
        rows.append("""            <tr>
        <td><a href="http://{0}/{1}">{1}</a></td>
        <td><a href="http://{0}/{2}">{2}</a></td>
    </tr>""".format(fqdn, prefix, redirect))

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
            <tr><th>Prefix</th><th>Redirect</th></tr>
{1}
        </table>
        <h2>Generated at: {2}</h2>
    </body>
</html>""".format(bucket, os.linesep.join(rows), datetime.datetime.now(), fqdn)
    return html


@click.command(context_settings=dict(help_option_names=['-h', '--help']))
@click.argument('bucket', type=click.STRING, required=True)
@click.argument('redirect-key', type=click.STRING, required=True)
@click.argument('target-key', type=click.STRING, required=True)
@click.option('-o', '--output-file', type=click.Path(file_okay=True, dir_okay=False, writable=True, readable=True))
@click.option('-u', '--update', is_flag=True, default=False)
def main(bucket, redirect_key, target_key, output_file, update):
    client = boto3.client('s3')

    if not test_bucket(client, bucket):
        exit_error("Unable to access bucket '{0}'".format(bucket), ErrorCodes.nobucketaccess)

    if not update and not test_key_available(client, redirect_key, bucket):
        exit_error("Key exists, exiting due to --update flag not specified.", ErrorCodes.keyexists)

    website_config = None
    try:
        website_config = get_website_config(client, bucket)
    except ClientError:
        exit_error("Failed to retrieve website config", ErrorCodes.websiteconfigerror)

    website_config.pop('ResponseMetadata', None)

    matching_rules = [r for r in website_config['RoutingRules'] if r['Condition']['KeyPrefixEquals'] == redirect_key]

    try:
        matching_rule = matching_rules[0]
        matching_rule['Redirect'].pop('ReplaceKeyWith', None)
        matching_rule['Redirect']['ReplaceKeyPrefixWith'] = target_key
        new_routing_rules = [l for l in website_config['RoutingRules'] if l != matching_rule]
    except IndexError:
        matching_rule = {
            'Redirect': {
                'ReplaceKeyPrefixWith': target_key
            },
            'Condition': {
                'KeyPrefixEquals': redirect_key
            }
        }
        new_routing_rules = website_config['RoutingRules']

    new_routing_rules.append(matching_rule)
    new_routing_rules.sort(key=lambda p: p['Condition']['KeyPrefixEquals'])

    website_config['RoutingRules'] = new_routing_rules

    try:
        put_website_config(client, bucket, website_config)
    except ClientError:
        exit_error("Failed to put updated website config", ErrorCodes.websiteconfigerror)

    website_endpoint = '{0}.{1}'.format(bucket, WEBSITE_SUFFIX)
    index_page_content = get_index_html(bucket, new_routing_rules, website_endpoint)
    print index_page_content

    try:
        put_website_index(client, bucket, output_file, index_page_content)
    except ClientError:
        exit_error("Failed to put updated website index", ErrorCodes.websiteconfigerror)

if __name__ == '__main__':
    main()
