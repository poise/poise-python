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

require 'serverspec'
set :backend, :exec

describe 'python_runtime' do
  describe file('/root/py2') do
    it { is_expected.to be_a_file }
    its(:content) { are_expected.to start_with '2.' }
  end

  describe file('/root/py3') do
    it { is_expected.to be_a_file }
    its(:content) { are_expected.to start_with '3.' }
  end
end

describe 'python_package' do
  describe 'django' do
    describe file('/root/django_sentinel') do
      it { is_expected.to be_a_file }
    end

    describe file('/root/py2_django') do
      it { is_expected.to be_a_file }
    end

    describe file('/root/py3_django') do
      it { is_expected.to_not be_a_file }
    end
  end

  describe 'pep8' do
    describe file('/root/py2_pep8') do
      it { is_expected.to_not be_a_file }
    end

    describe file('/root/py3_pep8') do
      it { is_expected.to be_a_file }
    end
  end

  describe 'setuptools' do
    describe file('/root/setuptools_sentinel') do
      it { is_expected.to_not be_a_file }
    end
  end
end
