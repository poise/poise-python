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


module PoisePython
  # Helper methods for Python-related things.
  #
  # @since 1.0.0
  module Utils
    autoload :PythonEncoder, 'poise_python/utils/python_encoder'
    extend self

    # Convert an object to a Python literal.
    #
    # @param obj [Object] Ovject to convert.
    # @return [String]
    def to_python(obj)
      PythonEncoder.new(obj).encode
    end
  end
end
