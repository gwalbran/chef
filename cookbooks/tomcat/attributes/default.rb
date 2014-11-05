#
# Cookbook Name:: tomcat
# Attributes:: default
#
# Copyright 2010, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

default["tomcat"]["version"] = '7'
default["tomcat"]["fine_version"] = "7.0.37"
default["tomcat"]["ports"]["port"] = 8005
default["tomcat"]["ports"]["connector_port"] = 8080
default["tomcat"]["ports"]["ssl_port"] = 8443
default["tomcat"]["ports"]["redirect_port"] = 8444
default["tomcat"]["ports"]["ajp_port"] = 8009
default["tomcat"]["java_options"] = "-Xmx128M -Djava.awt.headless=true"
default["tomcat"]["use_security_manager"] = false
default["tomcat"]["log_level"] = "SEVERE"
default["tomcat"]["default_instance_name"] = "default"
default["tomcat"]["instances"] = []

case platform
when "centos","redhat","fedora"
  default["tomcat"]["user"] = "tomcat#{tomcat["version"]}"
  default["tomcat"]["group"] = "tomcat#{tomcat["version"]}"
  default["tomcat"]["home"] = "/usr/share/tomcat#{tomcat["version"]}"
  default["tomcat"]["base"] = "/usr/share/tomcat#{tomcat["version"]}"
  default["tomcat"]["config_dir"] = "/etc/tomcat#{tomcat["version"]}"
  default["tomcat"]["log_dir"] = "/var/log/tomcat#{tomcat["version"]}"
  default["tomcat"]["tmp_dir"] = "/var/cache/tomcat#{tomcat["version"]}/temp"
  default["tomcat"]["work_dir"] = "/var/cache/tomcat#{tomcat["version"]}/work"
  default["tomcat"]["context_dir"] = "#{tomcat["config_dir"]}/Catalina/localhost"
  default["tomcat"]["webapp_dir"] = "/var/lib/tomcat#{tomcat["version"]}/webapps"
when "debian","ubuntu"
  default["tomcat"]["user"] = "tomcat#{tomcat["version"]}"
  default["tomcat"]["group"] = "tomcat#{tomcat["version"]}"
  default["tomcat"]["home"] = "/usr/share/tomcat#{tomcat["version"]}"
  default["tomcat"]["base"] = "/var/lib/tomcat#{tomcat["version"]}"
  default["tomcat"]["config_dir"] = "/etc/tomcat#{tomcat["version"]}"
  default["tomcat"]["log_dir"] = "/var/log/tomcat#{tomcat["version"]}"
  default["tomcat"]["tmp_dir"] = "/tmp/tomcat#{tomcat["version"]}-tmp"
  default["tomcat"]["work_dir"] = "/var/cache/tomcat#{tomcat["version"]}"
  default["tomcat"]["context_dir"] = "#{tomcat["config_dir"]}/Catalina/localhost"
  default["tomcat"]["webapp_dir"] = "/var/lib/tomcat#{tomcat["version"]}/webapps"
else
  default["tomcat"]["user"] = "tomcat#{tomcat["version"]}"
  default["tomcat"]["group"] = "tomcat#{tomcat["version"]}"
  default["tomcat"]["home"] = "/usr/share/tomcat#{tomcat["version"]}"
  default["tomcat"]["base"] = "/var/lib/tomcat#{tomcat["version"]}"
  default["tomcat"]["config_dir"] = "/etc/tomcat#{tomcat["version"]}"
  default["tomcat"]["log_dir"] = "/var/log/tomcat#{tomcat["version"]}"
  default["tomcat"]["tmp_dir"] = "/tmp/tomcat#{tomcat["version"]}-tmp"
  default["tomcat"]["work_dir"] = "/var/cache/tomcat#{tomcat["version"]}"
  default["tomcat"]["context_dir"] = "#{tomcat["config_dir"]}/Catalina/localhost"
  default["tomcat"]["webapp_dir"] = "/var/lib/tomcat#{tomcat["version"]}/webapps"
end

# Max threads will be set to number of cores times 4 - that should be enough!
# Tomcat original default is 200
default['tomcat']['max_threads']  = node['cpu']['total'] ? (node['cpu']['total'] * 4).to_i : 200

default['tomcat']['java_options'] = "-Xmx2G -Xms1G -XX:PermSize=128m -XX:MaxPermSize=256m -XX:+HeapDumpOnOutOfMemoryError"
default['tomcat']['jmx_remote_port_prefix'] = '2'
default['tomcat']['jmx_options'] = "-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=%d -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"
default['tomcat']['max_post_size'] = 15 * 1024 * 1024 # bytes
