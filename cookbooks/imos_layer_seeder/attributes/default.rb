# Where to get layer seeder from
default['imos_layer_seeder']['base_url']  = "https://raw.githubusercontent.com/aodn/utilities/master/geowebcache_seeder"

# Some layer seeder defaults
default['imos_layer_seeder']['geonetwork']     = "https://catalogue-portal.aodn.org.au/geonetwork"
default['imos_layer_seeder']['geoserver']      = "http://geoserver-123.aodn.org.au/geoserver/wms"
default['imos_layer_seeder']['type']           = "seed"
default['imos_layer_seeder']['start_zoom']     = 2
default['imos_layer_seeder']['end_zoom']       = 5

# Scheduling of layer seeder
default['imos_layer_seeder']['minute']    = '0'
default['imos_layer_seeder']['hour']      = '6'
default['imos_layer_seeder']['day']       = '*'
default['imos_layer_seeder']['month']     = '*'
default['imos_layer_seeder']['weekday']   = '*'
default['imos_layer_seeder']['duration']  = '2h'


default["imos_layer_seeder"]["log_dir"] = "/mnt/ebs/log/layer_seeder"