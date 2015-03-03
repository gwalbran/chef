# DNS

## Managed DNS

In every node you if you have the following snippet, DNS will be handled for
it:
```
"network": {
    "public_ipv4": "115.146.84.197"
},
"fqdn": "1-nec-mel.emii.org.au",
"aliases": [
    "edge.aodn.org.au",
    "portal-edge.aodn.org.au"
]
```

This will create the following records:

|Record Type|Name                   |Value                |
|-----------|-----------------------|---------------------|
|A          |1-nec-mel.emii.org.au  |115.146.84.197       |
|CNAME      |edge.aodn.org.au       |1-nec-mel.emii.org.au|
|CNAME      |portal-edge.aodn.org.au|1-nec-mel.emii.org.au|

## Unmanaged DNS records

For some services we create redundancy by creating redundant DNS records. This
describes how the records look like. Please note they are completely unmanaged
by Chef and are created in a manual manner in Route53.

Say we want to make the geoserver-123.aodn.org.au record redundant on the
hosts:
 * 1-aws-syd.emii.org.au (primary)
 * 12-nsp-mel.emii.org.au (failover)

We will create the following Route53 health checks:
 * geoserver-123-1-aws-syd (checks geoserver-123 on 1-aws-syd)
 * geoserver-123-12-nsp-mel (checks geoserver-123 on 12-nsp-mel)

Next we will have the following records configured:

|Record Type|Alias|Name                                |Value                               |Routing Policy                                               |
|-----------|-----|------------------------------------|------------------------------------|------------------------------------------------------------|
|CNAME      |NO   |geoserver-123-1-aws-syd.aodn.org.au |1-aws-syd.emii.org.au               |                                                            |
|CNAME      |NO   |geoserver-123-aws-syd.aodn.org.au   |geoserver-123-1-aws-syd.emii.org.au |Weighted, 10, Assoc w/ health check geoserver-123-1-aws-syd |
|CNAME      |YES  |geoserver-123.aodn.org.au           |geoserver-123-aws-syd.aodn.org.au   |Failover, geoserver-123-Primary, Eval Target Health         |
|CNAME      |NO   |geoserver-123-12-nsp-mel.aodn.org.au|12-nsp-mel.emii.org.au              |                                                            |
|CNAME      |NO   |geoserver-123-nsp-mel.aodn.org.au   |geoserver-123-12-nsp-mel.emii.org.au|Weighted, 10, Assoc w/ health check geoserver-123-12-nep-mel|
|CNAME      |YES  |geoserver-123.aodn.org.au           |geoserver-123-nsp-mel.aodn.org.au   |Failover, geoserver-123-Secondary, Eval Target Health       |

This will generate the following DNS logic (.aodn.org.au implicit):
 * geoserver-123 -> geoserver-123-aws-syd -> geoserver-123-1-aws-syd Health Check -> geoserver-123-1-aws-syd
 * geoserver-123 -> geoserver-123-nsp-mel -> geoserver-123-12-nsp-mel Health Check -> geoserver-123-12-nsp-mel

If needed, you can also add more primary servers to `geoserver-123-aws-syd` such
as 2-aws-syd.emii.org.au or more secondary servers to `geoserver-123-nsp-mel`.
