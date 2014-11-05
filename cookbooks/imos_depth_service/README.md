Description
===========

imos_depth_service simply install a CGI script to provide access to depth at
a given point.

Requirements
============

An apache web server with a virtual host and the following configuration:
```
ScriptAlias / /var/www/depthservice/
<Directory "/var/www/depth-service">
  AllowOverride None
  Options ExecCGI -MultiViews +SymLinksIfOwnerMatch
  Order allow,deny
  Allow from all
</Directory>
```

Attributes
==========

Usage
=====

