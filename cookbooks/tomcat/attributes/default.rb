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

default["tomcat"]["fine_version"] = "7.0.61"
default["tomcat"]["version"] = node["tomcat"]["fine_version"].split(".")[0]
default["tomcat"]["ports"]["port"] = 8005
default["tomcat"]["ports"]["connector_port"] = 8080
default["tomcat"]["ports"]["ssl_port"] = 8443
default["tomcat"]["ports"]["redirect_port"] = 8444
default["tomcat"]["ports"]["ajp_port"] = 8009
default["tomcat"]["java_options"] = "-Xmx128M -Djava.awt.headless=true"
default["tomcat"]["log_level"] = "SEVERE"

default["tomcat"]["pkg_url"] = "https://archive.apache.org/dist/tomcat/tomcat-7/v7.0.61/bin/apache-tomcat-7.0.61.tar.gz"
default["tomcat"]["pkg_checksum"] = "2528ad7434e44ab1198b5692d5f831ac605051129119fd81a00d4c75abe1c0e0"
#default["tomcat"]["pkg_url"] = "https://archive.apache.org/dist/tomcat/tomcat-8/v8.0.32/bin/apache-tomcat-8.0.32.tar.gz"
#default["tomcat"]["pkg_checksum"] = "7e23260f2481aca88f89838e91cb9ff00548a28ba5a19a88ff99388c7ee9a9b8"

default["tomcat"]["user"] = "tomcat7"
default["tomcat"]["group"] = "tomcat7"
default["tomcat"]["home"] = "/usr/share/tomcat7"
default["tomcat"]["base"] = "/var/lib/tomcat7"

# Max threads will be set to number of cores times 4 - that should be enough!
# Tomcat original default is 200
default['tomcat']['max_threads']  = node['cpu']['total'] ? (node['cpu']['total'] * 4).to_i : 200

default['tomcat']['java_options'] = "-Xmx2G -Xms1G -XX:PermSize=128m -XX:MaxPermSize=256m -XX:+HeapDumpOnOutOfMemoryError"
default['tomcat']['jmx_remote_port_prefix'] = '2'
default['tomcat']['jmx_options'] = "-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=%d -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"
default['tomcat']['max_post_size'] = 15 * 1024 * 1024 # bytes
