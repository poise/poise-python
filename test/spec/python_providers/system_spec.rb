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

require 'spec_helper'

describe PoisePython::PythonProviders::System do
  let(:python_version) { nil }
  let(:chefspec_options) { {platform: 'ubuntu', version: '14.04'} }
  let(:default_attributes) { {poise_python_version: python_version} }
  let(:python_runtime) { chef_run.python_runtime('test') }
  let(:system_package_candidates) { python_runtime.provider_for_action(:install).send(:system_package_candidates, python_version) }
  step_into(:python_runtime)
  recipe do
    python_runtime 'test' do
      version node['poise_python_version']
      virtualenv_version false
    end
  end

  shared_examples_for 'system provider' do |candidates, pkg|
    it { expect(python_runtime.provider_for_action(:install)).to be_a described_class }
    it { expect(system_package_candidates).to eq candidates }
    it { is_expected.to install_poise_languages_system(pkg) }
    it do
      expect_any_instance_of(described_class).to receive(:install_system_packages)
      run_chef
    end
  end

  context 'with version ""' do
    let(:python_version) { '' }
    it_behaves_like 'system provider', %w{python3.5 python35 python3.4 python34 python3.3 python33 python3.2 python32 python3.1 python31 python3.0 python30 python3 python2.7 python27 python2.6 python26 python2.5 python25 python}, 'python3.4'
  end # /context with version ""

  context 'with version 2' do
    let(:python_version) { '2' }
    it_behaves_like 'system provider', %w{python2.7 python27 python2.6 python26 python2.5 python25 python}, 'python2.7'
  end # /context with version 2

  context 'with version 3' do
    let(:python_version) { '3' }
    it_behaves_like 'system provider', %w{python3.5 python35 python3.4 python34 python3.3 python33 python3.2 python32 python3.1 python31 python3.0 python30 python3 python}, 'python3.4'
  end # /context with version 3

  context 'with version 2.3' do
    let(:python_version) { '2.3' }
    before do
      default_attributes['poise-python'] ||= {}
      default_attributes['poise-python']['test'] = {'package_name' => 'python2.3'}
    end
    it_behaves_like 'system provider', %w{python2.3 python23 python}, 'python2.3'
  end # /context with version 2.3

  context 'action :uninstall' do
    recipe do
      python_runtime 'test' do
        action :uninstall
        version node['poise_python_version']
      end
    end

    it do
      expect_any_instance_of(described_class).to receive(:uninstall_system_packages)
      run_chef
    end
  end # /context action :uninstall
end
