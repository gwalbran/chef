#
# Cookbook Name:: imos_webapps
# Library:: parallel_deploy
#
# Copyright 2014, IMOS
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0c
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module ParallelDeploy

  def self.add_version(path, version)
    if !version || version.empty?
      return path
    else
      return path + "##" + version
    end
  end

  def self.tomcat_version_for_artifact(artifact)
    begin
      return ::File.stat(artifact).mtime.to_i.to_s
    rescue
      return ""
    end
  end

end

