imos_dns Cookbook
=================
This cookbook synchronizes AWS Route53 with the DNS records IMOS has.

Requirements
------------
Requires the route53 cookbook

Attributes
----------

#### imos_dns::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['imos_dns']['dns_data_bag']</tt></td>
    <td>String</td>
    <td>Name of DNS data bag</td>
    <td><tt>dns</tt></td>
  </tr>
  <tr>
    <td><tt>['imos_dns']['aliases_attribute']</tt></td>
    <td>String</td>
    <td>Name of node attribute with aliases</td>
    <td><tt>aliases</tt></td>
  </tr>
  <tr>
    <td><tt>['imos_dns']['fqdn_attribute']</tt></td>
    <td>String</td>
    <td>Name of node attribute with FQDN</td>
    <td><tt>fqdn</tt></td>
  </tr>
  <tr>
    <td><tt>['imos_dns']['ipaddress_attribute']</tt></td>
    <td>String</td>
    <td>JSON path for public IP address attribute</td>
    <td><tt>['network']['public_ipv4']</tt></td>
  </tr>
  <tr>
    <td><tt>['imos_dns']['records_attribute']</tt></td>
    <td>String</td>
    <td>Name of data bag attribute with 'unmanaged' records</td>
    <td><tt>records</tt></td>
  </tr>
  <tr>
    <td><tt>['imos_dns']['users_domain']</tt></td>
    <td>String</td>
    <td>Name of domain to manage users on</td>
    <td><tt>emii.org.au</tt></td>
  </tr>
</table>

Usage
-----
Just include `imos_dns` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[imos_dns]"
  ]
}
```

Example data bag:
```json
{
  "id":"aodn_org_au",
  "zone_id": "AWS_ZONE_ID",
  "records": [
    [ "A", "shitty.aodn.org.au", "1.1.1.1" ],
    [ "A", "crappy.aodn.org.au", "2.2.2.2" ],
    [ "CNAME", "cname1.aodn.org.au", "somewhere.com" ],
    [ "CNAME", "cname2.aodn.org.au", "somewhere.com" ]
  ]
}
```

License and Authors
-------------------
Authors:
 * Dan Fruehauf <dan.fruehauf@utas.edu.au>
