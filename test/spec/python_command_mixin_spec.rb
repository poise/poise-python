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

describe PoisePython::PythonCommandMixin do
  describe PoisePython::PythonCommandMixin::Resource do
    resource(:poise_test) do
      include described_class
    end
    provider(:poise_test)

    describe '#python' do
      let(:python) { chef_run.python_runtime('test') }

      context 'with an implicit parent' do
        recipe do
          python_runtime 'test' do
            provider :dummy
          end
          poise_test 'test'
        end

        it { is_expected.to run_poise_test('test').with(parent_python: python, python: '/python') }
      end # /context with an implicit parent

      context 'with a parent resource' do
        recipe do
          r = python_runtime 'test' do
            provider :dummy
          end
          poise_test 'test' do
            python r
          end
        end

        it { is_expected.to run_poise_test('test').with(parent_python: python, python: '/python') }
      end # /context with a parent resource

      context 'with a parent resource name' do
        recipe do
          python_runtime 'test' do
            provider :dummy
          end
          poise_test 'test' do
            python 'test'
          end
        end

        it { is_expected.to run_poise_test('test').with(parent_python: python, python: '/python') }
      end # /context with a parent resource name

      context 'with a parent resource name that looks like a path' do
        let(:python) { chef_run.python_runtime('/usr/bin/other') }
        recipe do
          python_runtime '/usr/bin/other' do
            provider :dummy
          end
          poise_test 'test' do
            python '/usr/bin/other'
          end
        end

        it { is_expected.to run_poise_test('test').with(parent_python: python, python: '/python') }
      end # /context with a parent resource name that looks like a path

      context 'with a path' do
        recipe do
          poise_test 'test' do
            python '/usr/bin/other'
          end
        end

        it { is_expected.to run_poise_test('test').with(parent_python: nil, python: '/usr/bin/other') }
      end # /context with a path

      context 'with a path and an implicit parent' do
        recipe do
          python_runtime 'test' do
            provider :dummy
          end
          poise_test 'test' do
            python '/usr/bin/other'
          end
        end

        it { is_expected.to run_poise_test('test').with(parent_python: python, python: '/usr/bin/other') }
      end # /context with a path and an implicit parent

      context 'with an invalid parent' do
        recipe do
          poise_test 'test' do
            python 'test'
          end
        end

        it { expect { subject }.to raise_error Chef::Exceptions::ResourceNotFound }
      end # /context with an invalid parent

    end # /describe #python
  end # /describe PoisePython::PythonCommandMixin::Resource
end
