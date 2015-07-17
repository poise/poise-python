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

require 'poise_python/resources/python_runtime_test'

# Install lsb-release because Debian 6 doesn't by default and serverspec requires it
package 'lsb-release' if platform?('debian') && node['platform_version'].start_with?('6')

python_runtime_test '2'

python_runtime_test '3'

python_runtime_test 'pypy'

python_runtime_test 'system' do
  version ''
  runtime_provider :system
end

python_runtime_test 'scl' do
  version ''
  runtime_provider :scl
  only_if { platform_family?('rhel') }
end
