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

require 'poise_python/resources/python_runtime_test'

# Install lsb-release because Debian 6 doesn't by default and serverspec requires it
package 'lsb-release' if platform?('debian') && node['platform_version'].start_with?('6')

# Which tests to run on each platform.
tests_to_run = value_for_platform(
  default:  %w{py2 py3 system pypy pip},
  centos: {default: %w{py2 py3 system scl pypy pip}},
  redhat: {default: %w{py2 py3 system scl pypy pip}},
  ubuntu: {
    '12.04' => %w{py2 pypy pip},
    'default' => %w{py2 py3 system pypy pip},
  },
  windows: {default: %w{py2 py3}},
)

%w{py2 py3 system pypy scl pip msi}.each do |test|
  unless tests_to_run.include?(test)
    file "/no_#{test}"
    next
  end

  case test
  when 'py2'
    python_runtime_test '2'
  when 'py3'
    python_runtime_test '3'
  when 'system'
    python_runtime_test 'system' do
      version ''
      runtime_provider :system
    end
  when 'scl'
    python_runtime_test 'scl' do
      version ''
      runtime_provider :scl
    end
  when 'pypy'
    python_runtime_test 'pypy'
  when 'pip'
    # Some pip-related tests that I don't need to run on every Python version.
    # Pip does plenty of testing on different Python versions and I already touch
    # the basics.
    pip_provider = value_for_platform_family(default: :portable_pypy, windows: :msi)
    # Check the baseline state, should pull the latest pip.
    python_runtime 'pip1' do
      provider pip_provider
      options path: '/test_pip1'
      version ''
    end
    # Check installing a requested version.
    python_runtime 'pip2' do
      pip_version '8.1.2'
      provider pip_provider
      options path: '/test_pip2'
      version ''
    end
    # Check installing the latest and reverting to an old version.
    python_runtime 'pip3' do
      provider pip_provider
      options path: '/test_pip3'
      version ''
    end
    python_runtime 'pip3b' do
      pip_version '7.1.2'
      provider pip_provider
      options path: '/test_pip3'
      version ''
    end
    # Test pip9 specifically just to be safe.
    python_runtime 'pip4' do
      pip_version '9.0.3'
      provider pip_provider
      options path: '/test_pip4'
      version ''
    end
    # Run a simple package install on each just to test things.
    (1..4).each do |n|
      python_package 'structlog' do
        python "pip#{n}"
      end
    end
  end
end
