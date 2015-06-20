#
# Copyright 2015, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/resource'
require 'poise'


module PoisePython
  module Resources
    # (see PythonRuntime::Resource)
    # @since 1.0.0
    module PythonRuntime
      # A `python_runtime` resource to manage Python installations.
      #
      # @provides python_runtime
      # @action install
      # @action uninstall
      # @example
      #   python_runtime '2.7'
      class Resource < Chef::Resource
        include Poise(inversion: true, container: true)
        provides(:python_runtime)
        actions(:install, :uninstall)

        # @!attribute version
        #   Version of Python to install.
        #   @return [String]
        attribute(:version, kind_of: String, name_attribute: true)

        # The path to the `python` binary for this Python installation. This is
        # an output property.
        #
        # @return [String]
        # @example
        #   execute "#{resources('python_runtime[2.7]').python_binary} myapp.py"
        def python_binary
          provider_for_action(:python_binary).python_binary
        end

        # The environment variables for this Python installation. This is an
        # output property.
        #
        # @return [Hash<String, String>]
        # @example
        #   execute '/opt/myapp.py' do
        #     environment resources('python_runtime[2.7]').python_environment
        #   end
        def python_environment
          provider_for_action(:python_environment).python_environment
        end
      end

      # Providers can be found under lib/poise_python/python_providers/
    end
  end
end
