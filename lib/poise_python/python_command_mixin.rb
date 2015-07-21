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

require 'shellwords'

require 'chef/mixin/which'
require 'poise'


module PoisePython
  # Mixin for resources and providers which run Python commands.
  #
  # @since 1.0.0
  module PythonCommandMixin
    include Poise::Utils::ResourceProviderMixin

    # Mixin for resources which run Python commands.
    module Resource
      include Poise::Resource
      include Chef::Mixin::Which
      poise_subresource(true)

      # @!attribute parent_python
      #   Parent Python installation.
      #   @return [PoisePython::Resources::PythonRuntime::Resource, nil]
      parent_attribute(:python, type: :python_runtime, optional: true)
      # @!attribute timeout
      #   Timeout for Python commands in seconds. Defauls to 900 (5 minutes).
      #   @return [Integer]
      attribute(:timeout, kind_of: Integer, default: 900)

      # @overload python()
      #   Get the path to the Python binary to use for this resource. This can
      #   be set via {#python}, {#virtualenv}, or defaults to finding the first
      #   Python on `$PATH`.
      #   @return [void]
      # @overload python(val)
      #   Set the Python binary to use for this resource. You can set using the
      #   name of a `python_runtime` resource or a path to an existing Python
      #   binary.
      #   @param val [String, Hash, Chef::Resource] Object to use as the
      #     interpreter.
      #   @return [void]
      def python(*args)
        unless args.empty?
          python_arg = parent_arg = nil
          arg = args.first
          # Figure out which property we are setting.
          if arg.is_a?(String)
            # Check if it is a python_runtime resource.
            begin
              parent_arg = run_context.resource_collection.find("python_runtime[#{arg}]")
            rescue Chef::Exceptions::ResourceNotFound
              # Check if something looks like a path, defined as containing
              # either / or \. While a single word could be a path, I think the
              # UX win of better error messages should take priority.
              might_be_path = arg =~ %r{/|\\}
              if might_be_path
                Chef::Log.debug("[#{self}] python_runtime[#{arg}] not found, treating it as a path")
                python_arg = arg
              else
                # Surface the error up to the user.
                raise
              end
            end
          else
            parent_arg = arg
          end
          # Set both attributes.
          parent_python(parent_arg)
          set_or_return(:python, python_arg, kind_of: [String, NilClass])
        else
          # Getter behavior. Using @python directly is kind of gross but oh well.
          @python || default_python_binary
        end
      end

      # Wrapper for setting the parent to be a virtualenv.
      #
      # @param name [String] Name of the virtualenv resource.
      # @return [void]
      def virtualenv(name)
        parent_python("python_virtualenv[#{name}]")
      end

      private

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
    end

    module Provider
      private

      # Run a command using Python. Parameters and return value match Chef's
      # `shell_out` helper.
      def python_shell_out(*command_args)
        options = if command_args.last.is_a?(Hash)
          command_args.pop.dup
        else
          {}
        end
        # Inject our environment variables if needed.
        if new_resource.parent_python
          options[:environment] = new_resource.parent_python.python_environment.merge(options[:environment] || {})
        end
        # Inject other options.
        options[:timeout] ||= new_resource.timeout
        command = if command_args.length == 1 && command_args.first.is_a?(String)
          # String mode, sigh.
          "#{new_resource.python} #{command_args.first}"
        else
          # Array mode. Handle both ('one', 'two') and (['one', 'two']).
          [new_resource.python] + command_args.flatten
        end
        Chef::Log.debug("[#{new_resource}] Running python command: #{command.is_a?(Array) ? Shellwords.shelljoin(command) : command}")
        # Run the command
        shell_out(command, options)
      end

      # `shell_out!` version of {#python_shell_out}.
      def python_shell_out!(*command_args)
        python_shell_out(*command_args).tap(&:error!)
      end
    end
  end
end
