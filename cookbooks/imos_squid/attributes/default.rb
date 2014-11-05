default['squid']['user']  = "proxy"
default['squid']['group'] = "proxy"

# 10GB of cache, by default (units are in MB)
default['squid']['cache_size']          = 10240
# Mostly caching tiles, so 200 should be enough (units are in KB)
default['squid']['maximum_object_size'] = 200

# Defaults for refresh_pattern
default['squid']['cache_min']     = 60
default['squid']['cache_percent'] = "100%"
default['squid']['cache_max']     = 60
default['squid']['extra_opts']    = ""

# Custom squid rules to add
default['squid']['custom_config'] = []
