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

require 'chef/provider'
require 'poise'

require 'poise_python/resources/python_runtime'


module PoisePython
  module PythonProviders
    class Base < Chef::Provider
      include Poise(inversion: :python_runtime)

      def self.default_inversion_options(node, new_resource)
        super.merge({
          pip_version: new_resource.pip_version,
          setuptools_version: new_resource.setuptools_version,
          version: new_resource.version,
          virtualenv_version: new_resource.virtualenv_version,
        })
      end

      # The `install` action for the `python_runtime` resource.
      #
      # @return [void]
      def action_install
        notifying_block do
          install_python
          install_pip
        end
      end

      # The `uninstall` action for the `python_runtime` resource.
      #
      # @abstract
      # @return [void]
      def action_uninstall
        notifying_block do
          uninstall_python
        end
      end

      # The path to the `python` binary. This is an output property.
      #
      # @abstract
      # @return [String]
      def python_binary
        raise NotImplementedError
      end

      # The environment variables for this Python. This is an output property.
      #
      # @return [Hash<String, String>]
      def python_environment
        {}
      end

      private

      # Install the Python runtime. Must be implemented by subclass.
      #
      # @abstract
      # @return [void]
      def install_python
        raise NotImplementedError
      end

      # Uninstall the Python runtime. Must be implemented by subclass.
      #
      # @abstract
      # @return [void]
      def uninstall_python
        raise NotImplementedError
      end

      # Install pip in to the Python runtime.
      #
      # @return [void]
      def install_pip
        return unless options[:pip_version]
        # If there is a : in the version, use it as a URL.
        pip_version = options[:pip_version]
        is_url = pip_version.is_a?(String) && pip_version.include?(':')
        python_runtime_pip new_resource.name do
          parent new_resource
          # If the version is `true`, don't pass it at all.
          version pip_version if !is_url && pip_version.is_a?(String)
          get_pip_url pip_version if is_url
        end
      end

      def install_setuptools
      end

    end
  end
end
