define :custom_templates do

  params[:templates].each do |template|

    # Create the directory.
    directory File.dirname(template[:path]) do
      owner     node['tomcat']['user']
      group     node['tomcat']['user']
      mode      0755
      recursive true
    end

    # Install the template.
    template template[:path] do
      source "custom/#{File.basename(template[:path])}.erb"
      owner  node['tomcat']['user']
      group  node['tomcat']['user']
      mode   0644

      variables ({
        :params => template[:params]
      })
    end
  end

end
