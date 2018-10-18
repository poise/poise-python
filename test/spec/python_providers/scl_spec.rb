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

describe PoisePython::PythonProviders::Scl do
  let(:python_version) { '' }
  let(:chefspec_options) { {platform: 'centos', version: '7.4.1708'} }
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

  shared_examples_for 'scl provider' do |pkg|
    it { expect(python_runtime.provider_for_action(:install)).to be_a described_class }
    it { is_expected.to install_poise_languages_scl(pkg) }
    it do
      expect_any_instance_of(described_class).to receive(:install_scl_package)
      run_chef
    end
  end

  context 'with version ""' do
    let(:python_version) { '' }
    it_behaves_like 'scl provider', 'rh-python36'
  end # /context with version ""

  context 'with version "2"' do
    let(:python_version) { '2' }
    it_behaves_like 'scl provider', 'python27'
  end # /context with version "2"

  context 'with version "3"' do
    let(:python_version) { '3' }
    it_behaves_like 'scl provider', 'rh-python36'
  end # /context with version "3"

  context 'with version "3.3"' do
    let(:python_version) { '3.3' }
    it_behaves_like 'scl provider', 'python33'
  end # /context with version "3.3"

  context 'with version "" on CentOS 6' do
    let(:chefspec_options) { {platform: 'centos', version: '6.9'} }
    let(:python_version) { '' }
    it_behaves_like 'scl provider', 'rh-python36'
  end # /context with version "" on CentOS 6

  context 'action :uninstall' do
    recipe do
      python_runtime 'test' do
        action :uninstall
        version node['poise_python_version']
      end
    end

    it do
      expect_any_instance_of(described_class).to receive(:uninstall_scl_package)
      run_chef
    end
    it { expect(python_runtime.provider_for_action(:uninstall)).to be_a described_class }
  end # /context action :uninstall
end
