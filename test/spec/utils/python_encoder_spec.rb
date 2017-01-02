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

describe PoisePython::Utils::PythonEncoder do
  let(:obj) { nil }
  subject { described_class.new(obj).encode }

  context 'with a string' do
    let(:obj) { 'foobar' }
    it { is_expected.to eq '"foobar"' }
  end # /context with a string

  context 'with a complicated string' do
    let(:obj) { "im\nalittle\"teapot'" }
    it { is_expected.to eq '"im\\nalittle\\"teapot\'"' }
  end # /context with a complicated string

  context 'with an integer' do
    let(:obj) { 123 }
    it { is_expected.to eq '123' }
  end # /context with an integer

  context 'with a float' do
    let(:obj) { 1.3 }
    it { is_expected.to eq '1.3' }
  end # /context with a float

  context 'with a hash' do
    let(:obj) { {foo: 'bar'} }
    it { is_expected.to eq '{"foo":"bar"}' }
  end # /context with a hash

  context 'with an array' do
    let(:obj) { ['foo', 1, 'bar'] }
    it { is_expected.to eq '["foo",1,"bar"]' }
  end # /context with an array

  context 'with true' do
    let(:obj) { true }
    it { is_expected.to eq 'True' }
  end # /context with true

  context 'with false' do
    let(:obj) { false }
    it { is_expected.to eq 'False' }
  end # /context with false

  context 'with nil' do
    let(:obj) { nil }
    it { is_expected.to eq 'None' }
  end # /context with nil

  context 'with a broken object' do
    let(:obj) do
      {}.tap {|obj| obj[:x] = obj }
    end
    it { expect { subject }.to raise_error ArgumentError }
  end # /context with a broken object

  context 'with a complex object' do
    let(:obj) { {a: [1, "2", true], b: false, c: {d: nil}} }
    it { is_expected.to eq '{"a":[1,"2",True],"b":False,"c":{"d":None}}' }
  end # /context with a complex object
end
