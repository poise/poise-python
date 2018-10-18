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

require 'rbconfig'

require 'serverspec'

if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
  set :backend, :cmd
  set :os, :family => 'windows'
else
  set :backend, :exec
end

# Set up the shared example for python_runtime_test.
RSpec.shared_examples 'a python_runtime_test' do |python_name, version=nil|
  let(:python_name) { python_name }
  let(:python_path) { File.join('', "python_test_#{python_name}") }
  # Helper for all the file checks.
  def self.assert_file(rel_path, should_exist=true, &block)
    describe rel_path do
      subject { file(File.join(python_path, rel_path)) }
      # Do nothing for nil.
      if should_exist == true
        it { is_expected.to be_a_file }
      elsif should_exist == false
        it { is_expected.to_not exist }
      end
      instance_eval(&block) if block
    end
  end

  describe 'python_runtime' do
    assert_file('version') do
      its(:content) { is_expected.to start_with version } if version
    end
  end

  describe 'python_package' do
    describe 'sqlparse' do
      assert_file('import_sqlparse_before', false)
      assert_file('import_sqlparse_mid')
      assert_file('import_sqlparse_after', false)
      assert_file('sentinel_sqlparse')
      assert_file('sentinel_sqlparse2', false)
    end

    describe 'setuptools' do
      assert_file('sentinel_setuptools', false)
    end

    describe 'pep8' do
      assert_file('import_pep8')
    end

    describe 'pytz' do
      assert_file('import_pytz')
    end
  end

  describe 'python_virtualenv' do
    assert_file('venv', nil) do
      it { is_expected.to be_a_directory }
    end
    assert_file('import_pytest', false)
    assert_file('import_pytest_venv')
  end

  describe 'pip_requirements' do
    assert_file('import_requests') do
      its(:content) { is_expected.to match /^2\.7\.0\s*$/ }
    end
    assert_file('import_six') do
      its(:content) { is_expected.to match /^1\.8\.0\s*$/ }
    end
  end

  describe 'non default version' do
    assert_file('import_requests_version') do
      its(:content) { is_expected.to match /^2\.8\.0\s*$/ }
    end
  end

  unless os[:family] == 'windows'
    describe 'user install' do
      assert_file('import_docopt')
    end
  end
end

describe 'python 2', unless: File.exist?('/no_py2') do
  it_should_behave_like 'a python_runtime_test', '2', '2'
end

describe 'python 3', unless: File.exist?('/no_py3') do
  it_should_behave_like 'a python_runtime_test', '3', '3'
end

describe 'pypy', unless: File.exist?('/no_pypy') do
  it_should_behave_like 'a python_runtime_test', 'pypy'
end

describe 'system provider', unless: File.exist?('/no_system') do
  it_should_behave_like 'a python_runtime_test', 'system'
end

describe 'scl provider', unless: File.exist?('/no_scl') do
  it_should_behave_like 'a python_runtime_test', 'scl'
end

describe 'pip reversion test', unless: File.exist?('/no_pip') do
  path_suffix = if os[:family] == 'windows'
    '/Scripts/python.exe'
  else
    '/bin/pypy'
  end

  # Confirm pip verisons.
  describe command("/test_pip1#{path_suffix} -m pip --version") do
    its(:exit_status) { is_expected.to eq 0 }
    its(:stdout) { is_expected.to include ' 18.' }
  end

  describe command("/test_pip2#{path_suffix} -m pip --version") do
    its(:exit_status) { is_expected.to eq 0 }
    its(:stdout) { is_expected.to include '8.1.2' }
  end

  describe command("/test_pip3#{path_suffix} -m pip --version") do
    its(:exit_status) { is_expected.to eq 0 }
    its(:stdout) { is_expected.to include '7.1.2' }
  end

  describe command("/test_pip4#{path_suffix} -m pip --version") do
    its(:exit_status) { is_expected.to eq 0 }
    its(:stdout) { is_expected.to include '9.0.3' }
  end

  # Check that structlog installed.
  describe command("/test_pip1#{path_suffix} -c 'import structlog'") do
    its(:exit_status) { is_expected.to eq 0 }
  end

  describe command("/test_pip2#{path_suffix} -c 'import structlog'") do
    its(:exit_status) { is_expected.to eq 0 }
  end

  describe command("/test_pip3#{path_suffix} -c 'import structlog'") do
    its(:exit_status) { is_expected.to eq 0 }
  end

  describe command("/test_pip4#{path_suffix} -c 'import structlog'") do
    its(:exit_status) { is_expected.to eq 0 }
  end
end
