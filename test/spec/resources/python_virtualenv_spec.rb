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

describe PoisePython::Resources::PythonVirtualenv do
  step_into(:python_virtualenv)
  let(:expect_cmd) { nil }
  let(:has_venv) { false }
  let(:venv_help_output) { '  --without-pip         Skips installing or upgrading pip in the virtual' }
  let(:expect_user) { nil }
  before do
    if expect_cmd
      expect_any_instance_of(PoisePython::Resources::PythonVirtualenv::Provider).to receive(:python_shell_out).with(%w{-m venv -h}).and_return(double(error?: !has_venv, stdout: venv_help_output))
      expect_any_instance_of(PoisePython::Resources::PythonVirtualenv::Provider).to receive(:python_shell_out!).with(expect_cmd, environment: be_a(Hash), user: expect_user, group: expect_user)
    end
  end

  context 'without venv' do
    let(:expect_cmd) { %w{-m virtualenv /test} }
    recipe do
      python_virtualenv '/test'
    end

    it { is_expected.to create_python_virtualenv('/test') }
    it { expect(chef_run.python_virtualenv('/test').python_binary).to eq '/test/bin/python' }
    it { expect(chef_run.python_virtualenv('/test').python_environment).to eq({}) }
    it { is_expected.to install_python_package('wheel').with(parent_python: chef_run.python_virtualenv('/test')) }
    it { is_expected.to install_python_package('setuptools').with(parent_python: chef_run.python_virtualenv('/test')) }
    it { is_expected.to_not install_python_package('virtualenv') }
    it { is_expected.to install_python_runtime_pip('/test').with(parent: chef_run.python_virtualenv('/test')) }
  end # /context without venv

  context 'with venv' do
    let(:has_venv) { true }
    let(:expect_cmd) { %w{-m venv --without-pip /test} }
    recipe do
      python_virtualenv '/test'
    end

    it { is_expected.to create_python_virtualenv('/test') }
  end # /context with venv

  context 'with venv on python 3.3' do
    let(:has_venv) { true }
    let(:venv_help_output) { '' }
    let(:expect_cmd) { %w{-m venv /test} }
    recipe do
      python_virtualenv '/test'
    end

    it { is_expected.to create_python_virtualenv('/test') }
  end # /context with venv on python 3.3

  context 'with system_site_packages' do
    let(:expect_cmd) { %w{-m virtualenv --system-site-packages /test} }
    recipe do
      python_virtualenv '/test' do
        system_site_packages true
      end
    end

    it { is_expected.to create_python_virtualenv('/test') }
  end # /context with system_site_packages

  context 'with a user and group' do
    let(:expect_cmd) { %w{-m virtualenv /test} }
    let(:expect_user) { 'me' }
    recipe do
      python_virtualenv '/test' do
        user 'me'
        group 'me'
      end
    end

    it { is_expected.to create_python_virtualenv('/test') }
    it { is_expected.to install_python_package('wheel').with(group: 'me', user: 'me') }
    it { is_expected.to install_python_package('setuptools').with(group: 'me', user: 'me') }
  end # /context with a user and group


  context 'with action :delete' do
    recipe do
      python_virtualenv '/test' do
        action :delete
      end
    end

    it { is_expected.to delete_python_virtualenv('/test') }
    it { is_expected.to delete_directory('/test') }
  end # /context with action :delete

  context 'with a parent Python' do
    let(:expect_cmd) { %w{-m virtualenv /test} }
    recipe do
      python_runtime '2' do
        def self.python_environment
          {'KEY' => 'VALUE'}
        end
      end
      python_virtualenv '/test'
    end

    it { is_expected.to create_python_virtualenv('/test') }
    it { expect(chef_run.python_virtualenv('/test').python_binary).to eq '/test/bin/python' }
    it { expect(chef_run.python_virtualenv('/test').python_environment).to eq({'KEY' => 'VALUE'}) }
  end # /context with a parent Python
end
