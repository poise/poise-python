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

describe PoisePython::PythonProviders::PortablePyPy do
  let(:python_version) { nil }
  let(:chefspec_options) { {platform: 'ubuntu', version: '14.04'} }
  let(:default_attributes) { {poise_python_version: python_version} }
  let(:python_runtime) { chef_run.python_runtime('test') }
  step_into(:python_runtime)
  recipe do
    python_runtime 'test' do
      provider_no_auto 'dummy'
      version node['poise_python_version']
      virtualenv_version false
    end
  end

  shared_examples_for 'portablepypy provider' do |base|
    it { expect(python_runtime.provider_for_action(:install)).to be_a described_class }
    it { is_expected.to install_poise_languages_static(File.join('', 'opt', base)).with(source: "https://bitbucket.org/squeaky/portable-pypy/downloads/#{base}-linux_x86_64-portable.tar.bz2") }
    it { expect(python_runtime.python_binary).to eq File.join('', 'opt', base, 'bin', 'pypy') }
  end

  context 'with version pypy' do
    let(:python_version) { 'pypy' }
    it_behaves_like 'portablepypy provider', 'pypy-5.7.1'
  end # /context with version pypy

  context 'with version pypy-2.4' do
    let(:python_version) { 'pypy-2.4' }
    it_behaves_like 'portablepypy provider', 'pypy-2.4'
  end # /context with version pypy-2.4

  context 'action :uninstall' do
    recipe do
      python_runtime 'test' do
        version 'pypy'
        action :uninstall
      end
    end

    it { is_expected.to uninstall_poise_languages_static('/opt/pypy-5.7.1') }
  end # /context action :uninstall
end
