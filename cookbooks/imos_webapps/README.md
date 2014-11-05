Description
===========
Cookbook that provides functionality to download IMOS build artifacts from
their respective stores and deploy them into a tomcat container with apache
support

Requirements
============
Look at `metadata.rb`

Attributes
==========
None

Usage
=====
For the generic recipe, the usage is pretty simple. Following is an example of
what you have to put in the node in order to get a random webapp to run:

```
{
    "run_list": [
        "recipe[imos_squid]",
        "recipe[ssl]",
        "recipe[imos_webapps::generic_webapp]"
    ],
    "aliases": [
        "geoserver-123-11-nsp-mel.aodn.org.au", domain name will be checked to make sure it exists in the webapp configuration
        "portal-123.aodn.org.au"
    ],
    # this is where the business starts
    "webapps": {
        "instances": [
            {
                # configuring a tomcat instance called geoserver_123, running on
                # vhost geoserver-123-11-nsp-mel.aodn.org.au
                # this parameter is the name of the tomcat instance
                "name":         "geoserver_123",
                # name of apache vhost
                "vhost":        "geoserver-123-11-nsp-mel.aodn.org.au",
                # any other aliases to configure with apache
                "aliases":      [
                    "wfs.aodn.org.au",
                    "wms.aodn.org.au",
                    "geoserver-123-nsp-mel.aodn.org.au",
                    "geoserver-123.aodn.org.au"
                ],
                # port for tomcat, must be unique!
                "port":         "8080",
                "java_options": "-Xmx5G -Xms512m -Dgt2.jdbc.trace=true -XX:MaxPermSize=128m -DGEOSERVER_DATA_DIR=/mnt/ebs/geoserver_123",
                "data_dir":     "/mnt/ebs/geoserver_123",
                # this instructs apache to run via squid, so the application is cached
                "cached":       true,
                "apps": [
                    {
                        # this application will run on http://localhost:8080/geoserver
                        "name":             "geoserver", # name of application within the tomcat instance
                        # instructing the deployment which imos_webapps
                        # artifact we want to deploy for this application
                        "artifact":         "geoserver-2-4-2-fetchsize",
                        # instruct the tomcat cookbook to use a chef definition
                        # called 'geoserver', this is not mandatory, but the
                        # definition must exist
                        "custom_def":       "geoserver",
                        # JNDIs configured for application
                        "jndis":            [ "harvest-read-123-11", "legacy-read-123-11" ],
                        # this is a freestyle parameter passed to the
                        # application specific definition
                        "git_branch":       "production",
                        # refresh patterns for squid
                        "refresh_patterns": [
                            {
                                "regex":      "(.+/)?wms\\?.*",
                                "extra_opts": "override-expire ignore-reload"
                            }
                        ]
                    }
                ]
            },
            {
                # deploying a very simple webapp, with no custom definitions
                # and with no surprises, see if you can understand for yourself
                # what's happenning here, if you followed the example above,
                # this should be much easier to understand
                "name":    "portal_imos123",
                "vhost":   "imos.aodn.org.au",
                "aliases": [ "portal-123.aodn.org.au", "123.aodn.org.au" ],
                "port":    "8087",
                "apps": [
                    {
                        "name":        "imos123",
                        "aliases":     [ "webportal", "imos" ],
                        "artifact":    "portal-3",
                        "jndis":       [ "portal_imos123" ],
                        "config_file": "Imos123.groovy",
                        "backup":      true
                    }
                ]
            }
        ]
    }
}
```
