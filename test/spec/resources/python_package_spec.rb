#
# Copyright 2015-2017, Noah Kantrowitz
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

require 'spec_helper'

describe PoisePython::Resources::PythonPackage do
  describe PoisePython::Resources::PythonPackage::Resource do
    describe '#response_file' do
      recipe do
        python_package 'foo' do
          response_file 'bar'
        end
      end

      it { expect { subject }.to raise_error NoMethodError }
    end # /describe #response_file

    describe '#response_file_variables' do
      recipe do
        python_package 'foo' do
          response_file_variables 'bar'
        end
      end

      it { expect { subject }.to raise_error NoMethodError }
    end # /describe #response_file_variables

    describe '#source' do
      recipe do
        python_package 'foo' do
          source 'bar'
        end
      end

      it { expect { subject }.to raise_error NoMethodError }
    end # /describe #source
  end # /describe PoisePython::Resources::PythonPackage::Resource

  describe PoisePython::Resources::PythonPackage::Provider do
    let(:test_resource) { PoisePython::Resources::PythonPackage::Resource.new('package', chef_run.run_context) }
    let(:test_provider) { described_class.new(test_resource, chef_run.run_context) }
    def stub_cmd(cmd, **options)
      options = options.dup
      array_13 = options.delete(:array_13)
      if array_13 && Gem::Requirement.create('>= 13').satisfied_by?(Gem::Version.create(Chef::VERSION))
        cmd = Shellwords.split(cmd)
      end
      output_options = {error?: options.delete(:error?) || false, stdout: options.delete(:stdout) || '', stderr: options.delete(:stderr) || ''}
      expect(test_provider).to receive(:python_shell_out!).with(cmd, options).and_return(double("python #{cmd} return", **output_options))
    end

    describe '#load_current_resource' do
      let(:package_name) { nil }
      let(:package_version) { nil }
      let(:test_resource) { PoisePython::Resources::PythonPackage::Resource.new(package_name, chef_run.run_context).tap {|r| r.version(package_version) if package_version } }
      let(:candidate_version) { subject; test_provider.candidate_version }
      subject { test_provider.load_current_resource }

      context 'with package_name foo' do
        let(:package_name) { 'foo' }
        before do
          stub_cmd(%w{-m pip.__main__ list}, environment: {'PIP_FORMAT' => 'json'}, stdout: '')
          stub_cmd(%w{- foo}, input: kind_of(String), stdout: '{"foo":"1.0.0"}')
        end

        its(:version) { is_expected.to be nil }
        it { expect(candidate_version).to eq '1.0.0' }
      end # /context with package_name foo

      context 'with package_name ["foo", "bar"]' do
        let(:package_name) { %w{foo bar} }
        before do
          stub_cmd(%w{-m pip.__main__ list}, environment: {'PIP_FORMAT' => 'json'}, stdout: '')
          stub_cmd(%w{- foo bar}, input: kind_of(String), stdout: '{"foo":"1.0.0","bar":"2.0.0"}')
        end

        its(:version) { is_expected.to eq [nil, nil] }
        it { expect(candidate_version).to eq %w{1.0.0 2.0.0} }
      end # /context with package_name ["foo", "bar"]

      context 'with a package with extras' do
        let(:package_name) { 'foo[bar]' }
        before do
          stub_cmd(%w{-m pip.__main__ list}, environment: {'PIP_FORMAT' => 'json'}, stdout: '')
          stub_cmd(%w{- foo}, input: kind_of(String), stdout: '{"foo":"1.0.0"}')
        end

        its(:version) { is_expected.to be nil }
        it { expect(candidate_version).to eq '1.0.0' }
      end # /context with a package with extras

      context 'with a package with underscores' do
        let(:package_name) { 'cx_foo' }
        before do
          stub_cmd(%w{-m pip.__main__ list}, environment: {'PIP_FORMAT' => 'json'}, stdout: '')
          stub_cmd(%w{- cx-foo}, input: kind_of(String), stdout: '{"cx-foo":"1.0.0"}')
        end

        its(:version) { is_expected.to be nil }
        it { expect(candidate_version).to eq '1.0.0' }
      end # /context with a package with underscores

      context 'with options' do
        let(:package_name) { 'foo' }
        before do
          test_resource.options('--index-url=http://example')
          stub_cmd("-m pip.__main__ list --index-url=http://example  ", environment: {'PIP_FORMAT' => 'json'}, stdout: '', array_13: true)
          stub_cmd("-  --index-url=http://example  foo", input: kind_of(String), stdout: '{"foo":"1.0.0"}', array_13: true)
        end

        its(:version) { is_expected.to be nil }
        it { expect(candidate_version).to eq '1.0.0' }
      end # /context with options

      context 'with list options' do
        let(:package_name) { 'foo' }
        before do
          test_resource.list_options('--index-url=http://example')
          stub_cmd("-m pip.__main__ list  --index-url=http://example ", environment: {'PIP_FORMAT' => 'json'}, stdout: '')
          stub_cmd("-   --index-url=http://example foo", input: kind_of(String), stdout: '{"foo":"1.0.0"}')
        end

        its(:version) { is_expected.to be nil }
        it { expect(candidate_version).to eq '1.0.0' }
      end # /context with list options

      context 'with array list options' do
        let(:package_name) { 'foo' }
        before do
          test_resource.list_options(%w{--index-url=http://example})
          stub_cmd(%w{-m pip.__main__ list --index-url=http://example}, environment: {'PIP_FORMAT' => 'json'}, stdout: '')
          stub_cmd(%w{-  --index-url=http://example foo}, input: kind_of(String), stdout: '{"foo":"1.0.0"}')
        end

        its(:version) { is_expected.to be nil }
        it { expect(candidate_version).to eq '1.0.0' }
      end # /context with array list options
    end # /describe #load_current_resource

    describe 'actions' do
      let(:package_name) { nil }
      let(:current_version) { nil }
      let(:candidate_version) { nil }
      let(:test_resource) { PoisePython::Resources::PythonPackage::Resource.new(package_name, chef_run.run_context) }
      subject { test_provider.run_action }
      before do
        current_version = self.current_version
        candidate_version = self.candidate_version
        allow(test_provider).to receive(:load_current_resource) do
          current_resource = double('current_resource', package_name: package_name, version: current_version)
          test_provider.instance_eval do
            @current_resource = current_resource
            @candidate_version = candidate_version
          end
        end
      end

      describe 'action :install' do
        before { test_provider.action = :install }

        context 'with package_name foo' do
          let(:package_name) { 'foo' }
          let(:candidate_version) { '1.0.0' }
          it do
            stub_cmd(%w{-m pip.__main__ install foo==1.0.0})
            subject
          end
        end # /context with package_name foo

        context 'with package_name ["foo", "bar"]' do
          let(:package_name) { %w{foo bar} }
          let(:candidate_version) { %w{1.0.0 2.0.0} }
          it do
            stub_cmd(%w{-m pip.__main__ install foo==1.0.0 bar==2.0.0})
            subject
          end
        end # /context with package_name ["foo", "bar"]

        context 'with options' do
          let(:package_name) { 'foo' }
          let(:candidate_version) { '1.0.0' }
          before { test_resource.options('--editable') }
          it do
            stub_cmd('-m pip.__main__ install --editable  foo\\=\\=1.0.0', array_13: true)
            subject
          end
        end # /context with options

        context 'with install options' do
          let(:package_name) { 'foo' }
          let(:candidate_version) { '1.0.0' }
          before { test_resource.install_options('--editable') }
          it do
            stub_cmd('-m pip.__main__ install  --editable foo\\=\\=1.0.0')
            subject
          end
        end # /context with install options

        context 'with array install options' do
          let(:package_name) { 'foo' }
          let(:candidate_version) { '1.0.0' }
          before { test_resource.install_options(%w{--editable}) }
          it do
            stub_cmd(%w{-m pip.__main__ install --editable foo==1.0.0})
            subject
          end
        end # /context with array install options

        context 'with a package with extras' do
          let(:package_name) { 'foo[bar]' }
          let(:candidate_version) { '1.0.0' }
          it do
            stub_cmd(%w{-m pip.__main__ install foo[bar]==1.0.0})
            subject
          end
        end # /context with a package with extras

        context 'with a package with underscores' do
          let(:package_name) { 'cx_foo' }
          let(:candidate_version) { '1.0.0' }
          it do
            stub_cmd(%w{-m pip.__main__ install cx_foo==1.0.0})
            subject
          end
        end # /context with a package with underscores
      end # /describe action :install

      describe 'action :upgrade' do
        before { test_provider.action = :upgrade }

        context 'with package_name foo' do
          let(:package_name) { 'foo' }
          let(:candidate_version) { '1.0.0' }
          it do
            stub_cmd(%w{-m pip.__main__ install --upgrade foo==1.0.0})
            subject
          end
        end # /context with package_name foo

        context 'with package_name ["foo", "bar"]' do
          let(:package_name) { %w{foo bar} }
          let(:candidate_version) { %w{1.0.0 2.0.0} }
          it do
            stub_cmd(%w{-m pip.__main__ install --upgrade foo==1.0.0 bar==2.0.0})
            subject
          end
        end # /context with package_name ["foo", "bar"]
      end # /describe action :upgrade

      describe 'action :remove' do
        before { test_provider.action = :remove }

        context 'with package_name foo' do
          let(:package_name) { 'foo' }
          let(:current_version) { '1.0.0' }
          it do
            stub_cmd(%w{-m pip.__main__ uninstall --yes foo})
            subject
          end
        end # /context with package_name foo

        context 'with package_name ["foo", "bar"]' do
          let(:package_name) { %w{foo bar} }
          let(:current_version) { %w{1.0.0 2.0.0} }
          it do
            stub_cmd(%w{-m pip.__main__ uninstall --yes foo bar})
            subject
          end
        end # /context with package_name ["foo", "bar"]
      end # /describe action :remove
    end # /describe actions

    describe '#parse_pip_list' do
      let(:text) { '' }
      subject { test_provider.send(:parse_pip_list, text) }

      context 'with no content' do
        it { is_expected.to eq({}) }
      end # /context with no content

      context 'with standard content' do
        let(:text) { <<-EOH }
eventlet (0.12.1)
Fabric (1.9.1)
fabric-rundeck (1.2, /Users/coderanger/src/bal/fabric-rundeck)
flake8 (2.1.0.dev0)
cx-Freeze (4.3.4)
EOH
        it { is_expected.to eq({'eventlet' => '0.12.1', 'fabric' => '1.9.1', 'fabric-rundeck' => '1.2', 'flake8' => '2.1.0.dev0', 'cx-freeze' => '4.3.4'}) }
      end # /context with standard content

      context 'with JSON content' do
        let(:text) { <<-EOH.strip }
[{"name":"eventlet","version":"0.12.1"}, {"name":"Fabric","version":"1.9.1"}, {"name":"fabric-rundeck","version":"1.2"}, {"name":"flake8","version":"2.1.0.dev0"}, {"name":"cx-Freeze","version":"4.3.4"}]
EOH
        it { is_expected.to eq({'eventlet' => '0.12.1', 'fabric' => '1.9.1', 'fabric-rundeck' => '1.2', 'flake8' => '2.1.0.dev0', 'cx-freeze' => '4.3.4'}) }
      end # /context with JSON content

      context 'with malformed content' do
        let(:text) { <<-EOH }
eventlet (0.12.1)
Fabric (1.9.1)
fabric-rundeck (1.2, /Users/coderanger/src/bal/fabric-rundeck)
flake 8 (2.1.0.dev0)
cx_Freeze (4.3.4)
EOH
        it { is_expected.to eq({'eventlet' => '0.12.1', 'fabric' => '1.9.1', 'fabric-rundeck' => '1.2', 'cx-freeze' => '4.3.4'}) }
      end # /context with malformed content
    end # /describe #parse_pip_list
  end # /describe PoisePython::Resources::PythonPackage::Provider
end
