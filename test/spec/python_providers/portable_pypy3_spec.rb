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

describe PoisePython::PythonProviders::PortablePyPy3 do
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

  shared_examples_for 'portablepypy3 provider' do |base, url=nil|
    it { expect(python_runtime.provider_for_action(:install)).to be_a described_class }
    it { is_expected.to install_poise_languages_static(File.join('', 'opt', base)).with(source: url || "https://bitbucket.org/squeaky/portable-pypy/downloads/#{base}-linux_x86_64-portable.tar.bz2") }
    it { expect(python_runtime.python_binary).to eq File.join('', 'opt', base, 'bin', 'pypy') }
  end

  context 'with version pypy3' do
    let(:python_version) { 'pypy3' }
    it_behaves_like 'portablepypy3 provider', 'pypy3-2.4'
  end # /context with version pypy3

  context 'with version pypy3-2.3.1' do
    let(:python_version) { 'pypy3-2.3.1' }
    it_behaves_like 'portablepypy3 provider', 'pypy3-2.3.1'
  end # /context with version pypy3-2.3.1


  context 'with version pypy3-5.5' do
    let(:python_version) { 'pypy3-5.5' }
    it_behaves_like 'portablepypy3 provider', 'pypy3-5.5-alpha-20161014', 'https://bitbucket.org/squeaky/portable-pypy/downloads/pypy3.3-5.5-alpha-20161014-linux_x86_64-portable.tar.bz2'
  end # /context with version pypy3-5.5

  context 'with version pypy3-5.7' do
    let(:python_version) { 'pypy3-5.7' }
    it_behaves_like 'portablepypy3 provider', 'pypy3-5.7.1-beta', 'https://bitbucket.org/squeaky/portable-pypy/downloads/pypy3.5-5.7.1-beta-linux_x86_64-portable.tar.bz2'
  end # /context with version pypy3-5.5

  context 'action :uninstall' do
    recipe do
      python_runtime 'test' do
        version 'pypy3'
        action :uninstall
      end
    end

    it { is_expected.to uninstall_poise_languages_static('/opt/pypy3-2.4') }
  end # /context action :uninstall
end
