# Where to get layer seeder from
default['imos_squid']['layer_seeder']['base_url']  = "https://raw.githubusercontent.com/aodn/utilities/master/geoserver/geoserver_seeder"

# Some layer seeder defaults
default['imos_squid']['layer_seeder']['geonetwork']     = "https://catalogue-123.aodn.org.au/geonetwork"
default['imos_squid']['layer_seeder']['geoserver']      = "http://geoserver-123.aodn.org.au/geoserver/wms"
default['imos_squid']['layer_seeder']['geoserver_port'] = 8080
default['imos_squid']['layer_seeder']['start_zoom']     = 2
default['imos_squid']['layer_seeder']['end_zoom']       = 5
default['imos_squid']['layer_seeder']['threads']        = 1
default['imos_squid']['layer_seeder']['tile_size']      = 256
default['imos_squid']['layer_seeder']['gutter_size']    = 20
default['imos_squid']['layer_seeder']['url_format']     = "LAYERS=layer_name&TRANSPARENT=TRUE&VERSION=1.1.1&FORMAT=image%2Fpng&QUERYABLE=true&EXCEPTIONS=application%2Fvnd.ogc.se_xml&SERVICE=WMS&REQUEST=GetMap&STYLES=&SRS=EPSG%3A4326&BBOX=0,0,0,0&WIDTH=256&HEIGHT=256"

# Scheduling of layer seeder
default['imos_squid']['layer_seeder']['minute']    = '0'
default['imos_squid']['layer_seeder']['hour']      = '6'
default['imos_squid']['layer_seeder']['day']       = '*'
default['imos_squid']['layer_seeder']['month']     = '*'
default['imos_squid']['layer_seeder']['weekday']   = '*'
default['imos_squid']['layer_seeder']['duration']  = '2h'
