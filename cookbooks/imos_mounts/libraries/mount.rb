#
# Copyright 2014, IMOS
#
# Authors:
#       Dan Fruehauf <dan.fruehauf@utas.edu.au>
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
#

# Mocking mounts when running in vagrant
class Chef
  class Provider
    class Mount

      class Mount < Chef::Provider::Mount
        # Do not mount these things in their original destination,
        # for instance this will mount /home on /home-mock instead
        # Mocking also /var/backups as vagrant will have a bit of a hard time
        # configuring it as a home directory on a mount point for the backups
        # user
        @@mounts_ignore = [ "/home", "/var/backups" ]

        require 'fileutils'

        def need_mock?(run_context)
          run_context.node.attributes['vagrant'] && @new_resource.fstype != 'fuse.sshfs'
        end

        def initialize(new_resource, run_context)
          super
          need_mock?(run_context) && mock_mount(@new_resource)
        end

        def mock_mount(resource)
          resource.device("/var/chef#{resource.mount_point}")
          resource.fstype("none")
          resource.options("bind,rw")

          # Mock the home directory mount just because on 5-nsp-mel (and
          # perhaps also other VMs) if you override /home with a mount, it'll
          # override the /home/vagrant directory and then you'll have no
          # access and be very very sad.
          if @@mounts_ignore.include?(resource.mount_point)
            mocked_directory = "#{resource.mount_point}-mock"
            FileUtils.mkdir_p mocked_directory
            resource.mount_point(mocked_directory)
          end
        end

        def action_mount
          if need_mock?(@run_context)
            Chef::Log.info("Mocking mount '#{@new_resource.mount_point}' -> '#{@new_resource.device}'")
            FileUtils.mkdir_p @new_resource.device
          end
          super
        end

      end

    end # class Mount
  end # class Provider
end # class Chef
