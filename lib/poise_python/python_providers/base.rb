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
          version: new_resource.version,
        })
      end

      # The `install` action for the `python_runtime` resource.
      #
      # @abstract
      # @return [void]
      def action_install
        raise NotImplementedError
      end

      # The `uninstall` action for the `python_runtime` resource.
      #
      # @abstract
      # @return [void]
      def action_uninstall
        raise NotImplementedError
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
    end
  end
end
