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
require 'chef/resource'
require 'poise'

require 'poise_ruby/resources/ruby_runtime'


module PoiseRuby
  module Resources
    # (see RubyExecute::Resource)
    # @since 2.0.0
    module RubyExecute
      # A `ruby_execute` resource to run Ruby scripts and commands.
      #
      # @provides ruby_execute
      # @action run
      # @example
      #   ruby_execute 'myapp.rb' do
      #     user 'myuser'
      #   end
      class Resource < Chef::Resource::Execute
        include Poise(parent: true)
        provides(:ruby_execute)
        actions(:run)

        # @!attribute parent_ruby
        #   Parent ruby installation.
        #   @return [PoiseRuby::Resources::Ruby::Resource, nil]
        parent_attribute(:ruby, type: PoiseRuby::Resources::RubyRuntime::Resource, optional: true)
        # @!attribute command
        #   Command to run. This should not include the ruby itself, just the
        #   arguments to it.
        #   @return [String, Array<String>]
        attribute(:command, kind_of: [String, Array], name_attribute: true)
        # @!attribute directory
        #   Working directory for the command.
        #   @return [String]
        attribute(:directory, kind_of: String)
        # @!attribute environment
        #   Environment variables for the command.
        #   @return [Hash]
        attribute(:environment, kind_of: Hash, default: lazy { Mash.new })
        # @!attribute user
        #   User to run the command as.
        #   @return [String]
        attribute(:user, kind_of: String)

        # For compatability with Chef's execute resource.
        alias_method :cwd, :directory

        # Nicer name for the DSL.
        alias_method :ruby, :parent_ruby
      end

      # The default provider for `ruby_execute`.
      #
      # @see Resource
      # @provides ruby_execute
      class Provider < Chef::Provider
        include Poise
        include Chef::Mixin::ShellOut
        include Chef::Mixin::Which
        provides(:ruby_execute)

        # The `run` action for `ruby_execute`. Run the command.
        #
        # @return [void]
        def action_run
          shell_out!(command, command_options)
          new_resource.updated_by_last_action(true)
        end

        private

        # The ruby binary to use for this command.
        #
        # @return [String]
        def ruby_binary
          if new_resource.parent_ruby
            new_resource.parent_ruby.ruby_binary
          else
            which('ruby')
          end
        end

        # Command to pass to shell_out.
        #
        # @return [String, Array<String>]
        def command
          ruby_binary = new_resource.parent_ruby ? new_resource.parent_ruby.ruby_binary : which('ruby')
          if new_resource.command.is_a?(Array)
            [ruby_binary] + new_resource.command
          else
            "#{ruby_binary} #{new_resource.command}"
          end
        end

        # Options to pass to shell_out.
        #
        # @return [Hash<Symbol, Object>]
        def command_options
          {}.tap do |opts|
            opts[:cwd] = new_resource.directory if new_resource.directory
            opts[:environment] = new_resource.environment unless new_resource.environment.empty?
            opts[:user] = new_resource.user if new_resource.user
            opts[:log_level] = :info
            opts[:log_tag] = new_resource.to_s
            if STDOUT.tty? && !Chef::Config[:daemon] && Chef::Log.info? && !new_resource.sensitive
              opts[:live_stream] = STDOUT
            end
          end
        end
      end
    end
  end
end
