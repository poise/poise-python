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

describe PoisePython::Resources::PythonRuntimePip do
  step_into(:python_runtime_pip)
  recipe do
    python_runtime 'test'
    python_runtime_pip 'test' do
      get_pip_url 'http://example.com/'
    end
  end
  before do
    provider = PoisePython::Resources::PythonRuntimePip::Provider
    allow_any_instance_of(provider).to receive(:pip_version).and_return(nil)
    allow_any_instance_of(provider).to receive(:bootstrap_pip)
  end

  # Make sure it can at least vaguely run.
  it { chef_run }
end
