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

# Install lsb-release because Debian 6 doesn't by default and serverspec requires it
package 'lsb-release' if platform?('debian') && node['platform_version'].start_with?('6')

# Install pythons.
python_runtime '2'

python_runtime '3'

# Create test scripts.
file '/root/poise_python_test.py' do
  user 'root'
  group 'root'
  mode '644'
  content <<-EOH
import sys, platform
open(sys.argv[1], 'w').write(platform.python_version())
EOH
end

file '/root/poise_python_test_import.py' do
  user 'root'
  group 'root'
  mode '644'
  content <<-EOH
try:
    import sys
    mod = __import__(sys.argv[1])
    open(sys.argv[2], 'w').write(mod.__version__)
except ImportError:
    pass
EOH
end

# Log out versions to check in serverspec.
python_execute '/root/poise_python_test.py /root/py2' do
  python '2'
end

python_execute '/root/poise_python_test.py /root/py3' do
  python '3'
end

# Sentinel for testing notifications.
file '/root/django_sentinel' do
  action :nothing
end

# Install Django using pip.
python_package 'django' do
  python '2'
  notifies :create, 'file[/root/django_sentinel]', :immediately
end

# Log Django versions.
python_execute '/root/poise_python_test_import.py django /root/py2_django' do
  python '2'
end

python_execute '/root/poise_python_test_import.py django /root/py3_django' do
  python '3'
end

# Test multipackage installs.
python_package ['pep8', 'pytz'] do
  python '3'
end

# Log pep8 versions.
python_execute '/root/poise_python_test_import.py pep8 /root/py2_pep8' do
  python '2'
end

python_execute '/root/poise_python_test_import.py pep8 /root/py3_pep8' do
  python '3'
end

# Sentinel for the setuptools install.
file '/root/setuptools_sentinel' do
  action :nothing
end

# Install setuptools. This should be a no-op.
python_package 'setuptools' do
  python '2'
  notifies :create, 'file[/root/setuptools_sentinel]', :immediately
end

# Create a virtualenv using Python 2.
python_virtualenv '/root/venv2' do
  python '2'
end

python_package 'Flask' do
  virtualenv '/root/venv2'
end

python_execute '/root/poise_python_test_import.py flask /root/py2_flask' do
  python '2'
end

python_execute '/root/poise_python_test_import.py flask /root/venv_flask' do
  virtualenv '/root/venv2'
end
