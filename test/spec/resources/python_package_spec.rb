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

describe PoisePython::Resources::PythonPackage do
  describe PoisePython::Resources::PythonPackage::Resource do
  end # /describe PoisePython::Resources::PythonPackage::Resource

  describe PoisePython::Resources::PythonPackage::Provider do
    let(:test_provider) { described_class.new(nil, nil) }

    describe '#parse_pip_outdated' do
      let(:text) { '' }
      subject { test_provider.send(:parse_pip_outdated, text) }

      context 'with no content' do
        it { is_expected.to eq({}) }
      end # /context with no content

      context 'with standard content' do
        let(:text) { <<-EOH }
boto (Current: 2.25.0 Latest: 2.38.0 [wheel])
botocore (Current: 0.56.0 Latest: 1.1.1 [wheel])
certifi (Current: 14.5.14 Latest: 2015.4.28 [wheel])
cffi (Current: 0.8.1 Latest: 1.1.2 [sdist])
Fabric (Current: 1.9.1 Latest: 1.10.2 [wheel])
EOH
        it { is_expected.to eq({'boto' => '2.38.0', 'botocore' => '1.1.1', 'certifi' => '2015.4.28', 'cffi' => '1.1.2', 'fabric' => '1.10.2'}) }
      end # /context with standard content
    end # /describe #parse_pip_outdated

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
EOH
        it { is_expected.to eq({'eventlet' => '0.12.1', 'fabric' => '1.9.1', 'fabric-rundeck' => '1.2', 'flake8' => '2.1.0.dev0'}) }
      end # /context with standard content
    end # /describe #parse_pip_list
  end # /describe PoisePython::Resources::PythonPackage::Provider
end
