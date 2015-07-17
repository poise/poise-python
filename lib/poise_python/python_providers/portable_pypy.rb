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

require 'poise_python/error'
require 'poise_python/python_providers/base'


module PoisePython
  module PythonProviders
    class PortablePyPy < Base
      provides(:portable_pypy)

      PYPY_PACKAGES = {
        'pypy' => %w{2.6 2.5.1 2.5 2.4 2.3.1 2.3 2.2.1 2.2 2.1 2.0.2},
        'pypy3' => %w{2.4 2.3.1},
      }

      # Only use this to install pypy.
      #
      # @api private
      def self.provides_auto?(node, resource)
        super || (resource.version.start_with?('pypy') && node['kernel']['name'].downcase == 'linux')
      end

      def python_binary
        ::File.join(pypy_folder, 'bin', 'pypy')
      end

      private

      def install_python
        path = ::File.join(Chef::Config[:file_cache_path], "#{pypy_package}.tar.bz2")
        folder = pypy_folder
        url = pypy_package_url

        package %w{tar bzip2}

        unpack = execute 'unpack pypy' do
          action :nothing
          command ['tar', 'xjvf', path]
          cwd ::File.dirname(folder)
        end

        remote_file path do
          source url
          owner 'root'
          group 'root'
          mode '644'
          notifies :run, unpack, :immediately
        end
      end

      def uninstall_python
        directory pypy_folder do
          action :remove
          recursive true
        end
      end

      def pypy_package
        @pypy_package ||= begin
          match = options['version'].match(/^(pypy(?:|3))(?:-(.*))?$/)
          package_type = match ? match[1] : 'pypy'
          version_prefix = (match && match[2]).to_s
          version = PYPY_PACKAGES[package_type].find {|v| v.start_with?(version_prefix) }
          "#{package_type}-#{version}-#{node['kernel']['name'].downcase}_#{node['kernel']['machine']}-portable"
        end
      end

      def pypy_folder
        ::File.join('', 'opt', pypy_package)
      end

      def pypy_package_url
        "https://bitbucket.org/squeaky/portable-pypy/downloads/#{pypy_package}.tar.bz2"
      end

    end
  end
end

