require 'chefspec'

describe 'tomcat::default' do

  instances = [
               { :name => "portal" },
               { :name =>"aatams" }
              ]

  let (:chef_run) {
    chef_run = ChefSpec::ChefRunner.new
    chef_run.node.set['tomcat']['instances'] = instances
    chef_run.converge 'tomcat::default'
  }

  instances.each { |instance|

    dir_name = "/var/lib/tomcat7/#{instance.name}"

    it 'create directory for each instance' do
      chef_run.should create_directory dir_name
      chef_run.directory(dir_name).should be_owned_by('tomcat7', 'tomcat7')
    end

    it 'tomcat installed' do
      chef_run.should execute_bash_script "extract tomcat for #{instance.name}"
    end

  }

  it 'check init.d scripts installed' do
    instances.each { |instance|
      chef_run.should create_file_with_content "/etc/init.d/tomcat7_#{instance.name}", "NAME=#{instance.name}"
    }
  end

  it 'install service tomcat7' do
    instances.each { |instance|
      chef_run.should set_service_to_start_on_boot "tomcat7_#{instance.name}"
     }
  end

end
