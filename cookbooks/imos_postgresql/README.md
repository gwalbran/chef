imos_postgresql Cookbook
========================
Take care of 'data warehouse' databases at IMOS.

Requirements
------------
Requires the the `postgresql` and `database` cookbooks.

Also requires the `backup` cookbook written at IMOS to provide granular backups
for databases.

Attributes
----------

#### imos_postgresql::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>[:imos_postgresql][:postgresql_databases_data_bag]</tt></td>
    <td>String</td>
    <td>Name of databases data bag to use</td>
    <td><tt>postgresql_databases</tt></td>
  </tr>
  <tr>
    <td><tt>[:imos_postgresql][:postgresql_users_data_bag]</tt></td>
    <td>String</td>
    <td>Name of users data bag to use</td>
    <td><tt>postgresql_users</tt></td>
  </tr>
</table>

Usage
-----

#### imos_postgresql::default
imos_postgresql::default will probe for all postgresql data bags defined on a
node and configure its databases, according to the information in the data bag.

Example for a node definition snippet creating a database defined in a data bag
called `aatams`:
```
{
  "run_list": [
    "recipe[imos_postgresql]"
  ],
  "normal": {
    "postgresql": {
      "databases": [
        "aatams3"
      ]
    }
  }
}
```

An example for a data bag called `aatams` defining the database `aatams`:
```
{
    "id":            "aatams3",
    "database_name": "aatams3",
    "template":      "template_postgis",
    "acl": [
        { "username": "aatams",    "grants": [ "all" ] }
        { "username": "aatams_ro", "grants": [ "select" ] }
    ],
    "backup": true
}
```
The above data bag defines database `aatams` with:
 * A database <b>owner</b> `aatams_admin` with password `supersecret` and privileges
`createdb`, `inherit` and `login`
   * <b>ORDER DOES MATTER: The first user defined will be the owner of the database<b>
 * A database user `aatams` with password `secret` and privileges `login`
(implicit)

All users above will have to be defined as `postgresql_users` data bags. For
example, lets define the `aatams` user:
```
{
    "id":            "aatams",
    "password":      "SECRET_KTHX_BYE",
    "privileges":    [ "createdb", "inherit", "login", "superuser" ]
}
```

Or, defining the `aatams_ro` user:
```
{
    "id":            "aatams_ro",
    "password":      "SOME_OTHER_SECRET_KTHX_BYE",
    "privileges":    [ "login" ]
}
```

License and Authors
-------------------
Authors:
 * Dan Fruehauf <dan.fruehauf@utas.edu.au>
