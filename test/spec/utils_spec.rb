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

describe PoisePython::Utils do
  describe '.to_python' do
    subject { described_class.to_python(1) }
    it { is_expected.to eq '1' }
    # More detailed encoder specs in python_encoder_spec.rb
  end # /describe .to_python

  describe '.path_to_module' do
    let(:path) { '' }
    let(:base) { nil }
    subject { described_class.path_to_module(path, base) }

    context 'with a relative path' do
      let(:path) { 'foo.py' }
      it { is_expected.to eq 'foo' }
    end  # /context with a relative path

    context 'with a nested relative path' do
      let(:path) { File.join('foo', 'bar', 'baz.py') }
      it { is_expected.to eq 'foo.bar.baz' }
    end  # /context with a nested relative path

    context 'with a non-.py file' do
      let(:path) { File.join('foo', 'bar', 'baz') }
      it { is_expected.to eq 'foo.bar.baz' }
    end  # /context with a non-.py file

    context 'with a base path' do
      let(:path) { File.join('', 'foo', 'bar', 'baz.py') }
      let(:base) { File.join('', 'foo') }
      it { is_expected.to eq 'bar.baz' }
    end  # /context with a base path

    context 'with a base path that does not match the path' do
      let(:path) { File.join('', 'foo', 'bar', 'baz.py') }
      let(:base) { File.join('', 'bar') }
      it { expect { subject }.to raise_error PoisePython::Error }
    end  # /context with a base path that does not match the path

    context 'with a base and relative path' do
      let(:path) { File.join('bar', 'baz.py') }
      let(:base) { File.join('', 'foo') }
      it { is_expected.to eq 'bar.baz' }
    end  # /context with a base and relative path
  end # /describe .path_to_module

  describe '.module_to_path' do
    let(:mod) { '' }
    let(:base) { nil }
    subject { described_class.module_to_path(mod, base) }

    context 'with a module' do
      let(:mod) { 'foo' }
      it { is_expected.to eq 'foo.py' }
    end  # /context with a module

    context 'with a nested module' do
      let(:mod) { 'foo.bar.baz' }
      it { is_expected.to eq File.join('foo', 'bar', 'baz.py') }
    end  # /context with a nested module

    context 'with a base path' do
      let(:mod) { 'bar.baz' }
      let(:base) { File.join('', 'foo') }
      it { is_expected.to eq File.join('', 'foo', 'bar', 'baz.py') }
    end  # /context with a base path
  end # /describe .module_to_path
end
