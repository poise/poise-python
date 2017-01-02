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

class PythonRuntimeTestProvider < PoisePython::PythonProviders::Base
  provides(:test)
  def self.provides_auto?(*args)
    true
  end
  def python_binary
    '/python'
  end
  def install_python
  end
  def uninstall_python
  end
end

describe PoisePython::Resources::PythonRuntime do
  step_into(:python_runtime)
  let(:venv_installed) { false }
  before do
    allow_any_instance_of(PythonRuntimeTestProvider).to receive(:poise_shell_out).with(%w{/python -m venv -h}, environment: {}).and_return(double(error?: !venv_installed))
  end

  context 'with defaults' do
    recipe do
      python_runtime 'test' do
        provider :test
      end
    end

    it { is_expected.to install_python_runtime_pip('test').with(version: nil, get_pip_url: 'https://bootstrap.pypa.io/get-pip.py') }
  end # /context with defaults

  context 'with a pip_version' do
    recipe do
      python_runtime 'test' do
        provider :test
        pip_version '1.2.3'
      end
    end

    it { is_expected.to install_python_runtime_pip('test').with(version: '1.2.3', get_pip_url: 'https://bootstrap.pypa.io/get-pip.py') }
  end # /context with a pip_version

  context 'with a pip_version URL' do
    recipe do
      python_runtime 'test' do
        provider :test
        pip_version 'http://example.com/get-pip.py'
      end
    end

    it { is_expected.to install_python_runtime_pip('test').with(version: nil, get_pip_url: 'http://example.com/get-pip.py') }
  end # /context with a pip_version URL

  context 'with a pip_version and a get_pip_url' do
    recipe do
      python_runtime 'test' do
        provider :test
        pip_version '1.2.3'
        get_pip_url 'http://example.com/get-pip.py'
      end
    end

    it { is_expected.to install_python_runtime_pip('test').with(version: '1.2.3', get_pip_url: 'http://example.com/get-pip.py') }
  end # /context with a pip_version and a get_pip_url
end
