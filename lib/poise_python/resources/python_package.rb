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

require 'chef/mixin/which'
require 'chef/provider/package'
require 'chef/resource/package'
require 'poise'


module PoisePython
  module Resources
    # (see PythonPackage::Resource)
    # @since 1.0.0
    module PythonPackage
      # A Python snippet to hack pip a bit so `pip list --outdated` will show
      # only the things we want and will understand version requirements.
      # @api private
      PIP_HACK_SCRIPT = <<-EOH
import sys

import pip
try:
    # >= 6.0
    from pip.utils import get_installed_distributions
except ImportError:
    # <= 1.5.6
    from pip.util import get_installed_distributions

def replacement(*args, **kwargs):
    import copy, sys
    from pip._vendor import pkg_resources
    dists = []
    for raw_req in sys.argv[3:]:
        req = pkg_resources.Requirement.parse(raw_req)
        dist = pkg_resources.working_set.by_key.get(req.key)
        if dist:
          # Don't mutate stuff from the global working set.
          dist = copy.copy(dist)
        else:
          # Make a fake one.
          dist = pkg_resources.Distribution(project_name=req.key, version='0')
        # Fool the .key property into using our string.
        dist._key = raw_req
        dists.append(dist)
    return dists
try:
    # For Python 2.
    get_installed_distributions.func_code = replacement.func_code
except AttributeError:
    # For Python 3.
    get_installed_distributions.__code__ = replacement.__code__

sys.exit(pip.main())
EOH

      # A `python_package` resource to manage Python installations.
      #
      # @provides python_package
      # @action install
      # @action upgrade
      # @action uninstall
      # @example
      #   TODO
      class Resource < Chef::Resource::Package
        include Poise(parent: true)
        include Chef::Mixin::Which
        provides(:python_package)

        def initialize(*args)
          super
          # For older Chef.
          @resource_name = :python_package
          # We don't have these actions.
          @allowed_actions.delete(:purge)
          @allowed_actions.delete(:reconfig)
        end

        # @!attribute parent_python
        #   Parent Python installation.
        #   @return [PoisePython::Resources::PythonRuntime::Resource, nil]
        parent_attribute(:python, type: :python_runtime, optional: true)
        attribute(:python_binary, kind_of: String, default: lazy { default_python_binary })

        # Nicer name for the DSL.
        alias_method :python, :parent_python

        # Compute the default path to the Python binary.
        #
        # @return [String]
        def default_python_binary
          if parent_python
            parent_python.python_binary
          else
            which('python')
          end
        end

        # Upstream attributes we don't support.
        # @api private
        def response_file(arg=nil)
          raise NoMethodError if arg
        end

        # @api private
        def response_file_variables(arg=nil)
          raise NoMemoryError if arg
        end

        # @api private
        def source(arg=nil)
          raise NoMethodError if arg
        end
      end

      # The default provider for the `python_package` resource.
      #
      # @see Resource
      class Provider < Chef::Provider::Package
        provides(:python_package)

        def load_current_resource
          @current_resource = new_resource.class.new(new_resource.name, run_context)
          current_resource.package_name(new_resource.package_name)
          check_package_versions(current_resource)
          current_resource
        end

        def check_package_versions(resource, version=new_resource.version)
          # Get the version for everything currently installed.
          list = pip_command('list').stdout
          version_data = parse_pip_list(list)
          # Check for newer candidates.
          outdated = pip_outdated(pip_requirements(resource.package_name, version)).stdout
          parse_pip_outdated(outdated).each do |name, candidate|
            # Merge candidates in to the existing versions. Might need to make
            # blank entry to a package that will be new.
            version_data[name] ||= {current: nil, candidate: nil}
            version_data[name][:candidate] = candidate
          end
          # Populate the current resource and candidate versions. Youch this is
          # a gross mix of data flow.
          if(resource.package_name.is_a?(Array))
            @candidate_version = []
            versions = []
            [resource.package_name].flatten.each do |name|
              ver = version_data[name]
              versions << (ver && ver[:current])
              @candidate_version << (ver && ver[:candidate])
            end
            resource.version(versions)
          else
            ver = version_data[resource.package_name]
            resource.version(ver && ver[:current])
            @candidate_version = ver && ver[:candidate]
          end
        end

        def install_package(name, version)
          pip_install(name, version, upgrade: false)
        end

        def upgrade_package(name, version)
          pip_install(name, version, upgrade: true)
        end

        def remove_package(name, version)
          pip_command('uninstall', %w{--yes} + [name].flatten)
        end

        private

        # Convert name(s) and version(s) to an array of pkg_resources.Requirement
        # compatible strings.
        #
        # @param name [String, Array<String>] Name or names for the packages.
        # @param version [String, Array<String>] Version or versions for the
        #   packages.
        # @return [Array<String>]
        def pip_requirements(name, version)
          [name].flatten.zip([version].flatten).map do |n, v|
            v = v.to_s.strip
            if v.empty?
              # No version requirement, send through unmodified.
              n
            elsif v =~ /^\d/
              "#{n}==#{v}"
            else
              # If the first character isn't a digit, assume something fancy.
              n + v
            end
          end
        end

        def pip_install(name, version, upgrade: false)
          cmd = pip_requirements(name, version)
          # Prepend --upgrade if needed.
          cmd = %w{--upgrade} + cmd if upgrade
          pip_command('install', cmd)
        end

        def pip_command(pip_command, pip_options=[], opts={})
          runner = opts.delete(:pip_runner) || %w{-m pip}
          full_cmd = if new_resource.options
            # We have to use a string for this case to be safe because the
            # options are a string and I don't want to try and parse that.
            "#{new_resource.python_binary} #{runner.join(' ')} #{pip_command} #{new_resource.options} #{pip_options.join(' ')}"
          else
            # No special options, use an array to skip the extra /bin/sh.
            [new_resource.python_binary] + runner + [pip_command] + pip_options
          end

          # Inject environment variables if needed.
          if new_resource.parent_python
            opts[:environment] = new_resource.parent_python.python_environment.merge(opts[:environment] || {})
          end

          # Run the command.
          shell_out_with_timeout!(full_cmd, opts)
        end

        def pip_outdated(requirements)
          pip_command('list', %w{--outdated} + requirements, input: PIP_HACK_SCRIPT, pip_runner: %w{-})
        end

        def parse_pip_outdated(text)
          text.split(/\n/).inject({}) do |memo, line|
            # Example of a line:
            # boto (Current: 2.25.0 Latest: 2.38.0 [wheel])
            if md = line.match(/^(\S+)\s+\(.*?latest:\s+([^\s,]+).*\)$/i)
              memo[md[1].downcase] = md[2]
            end
            memo
          end
        end

        def parse_pip_list(text)
          text.split(/\n/).inject({}) do |memo, line|
            # Example of a line:
            # boto (2.25.0)
            if md = line.match(/^(\S+)\s+\(([^\s,]+).*\)$/i)
              memo[md[1].downcase] = {current: md[2], candidate: md[2]}
            end
            memo
          end
        end

      end
    end
  end
end
