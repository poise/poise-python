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

describe PoisePython::Resources::PipRequirements do
  let(:pip_cmd) { %w{-m pip.__main__ install --requirement /test/requirements.txt} }
  let(:pip_output) { '' }
  let(:pip_user) { nil }
  let(:pip_group) { nil }
  let(:pip_cwd) { '/test' }
  step_into(:pip_requirements)
  before do
    allow(File).to receive(:directory?).and_call_original
    allow(File).to receive(:directory?).with('/test').and_return(true)
  end
  before do
    expect_any_instance_of(PoisePython::Resources::PipRequirements::Provider).to receive(:python_shell_out!).with(pip_cmd, {user: pip_user, group: pip_group, cwd: pip_cwd}).and_return(double(stdout: pip_output))
  end

  context 'with a directory' do
    recipe do
      pip_requirements '/test'
    end

    it { is_expected.to install_pip_requirements('/test') }
  end # /context with a directory

  context 'with a file' do
    let(:pip_cmd) { %w{-m pip.__main__ install --requirement /test/reqs.txt} }
    recipe do
      pip_requirements '/test/reqs.txt'
    end

    it { is_expected.to install_pip_requirements('/test/reqs.txt') }
  end # /context with a file

  context 'with a user' do
    let(:pip_user) { 'testuser' }
    recipe do
      pip_requirements '/test' do
        user 'testuser'
      end
    end

    it { is_expected.to install_pip_requirements('/test') }
  end # /context with a user

  context 'with a group' do
    let(:pip_group) { 'testgroup' }
    recipe do
      pip_requirements '/test' do
        group 'testgroup'
      end
    end

    it { is_expected.to install_pip_requirements('/test') }
  end # /context with a group

  context 'action :upgrade' do
    let(:pip_cmd) { %w{-m pip.__main__ install --upgrade --requirement /test/requirements.txt} }
    recipe do
      pip_requirements '/test' do
        action :upgrade
      end
    end

    it { is_expected.to upgrade_pip_requirements('/test') }
  end # /context action :upgrade

  context 'with output' do
    let(:pip_output) { 'Successfully installed' }
    recipe do
      pip_requirements '/test'
    end

    it { is_expected.to install_pip_requirements('/test').with(updated?: true) }
  end # /context with output

  context 'with a cwd' do
    let(:pip_cwd) { '/other' }
    recipe do
      pip_requirements '/test' do
        cwd '/other'
      end
    end

    it { is_expected.to install_pip_requirements('/test') }
  end # /context with a cwd

  context 'with options' do
    let(:pip_cmd) { '-m pip.__main__ install --index-url=http://example --requirement /test/requirements.txt' }
    recipe do
      pip_requirements '/test' do
        options '--index-url=http://example'
      end
    end

    it { is_expected.to install_pip_requirements('/test') }
  end # /context with options
end
