include_recipe "java"

# Required for grails to run.
if node['java']['install_flavor'] == "openjdk"
  execute "set Open JDK as alternative" do
    command "update-alternatives --set java /usr/lib/jvm/java-#{node["java"]["jdk_version"]}-openjdk-amd64/jre/bin/java"
    action :run
  end
end
