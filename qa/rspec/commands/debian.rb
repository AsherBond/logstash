# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require_relative "base"

module ServiceTester
  class DebianCommands < Base

    include ::ServiceTester::SystemD

    def installed?(package)
      stdout = ""
      cmd = sudo_exec!("dpkg -s #{package}")
      stdout = cmd.stdout
      stdout.match(/^Package: #{package}$/)
      stdout.match(/^Status: install ok installed$/)
    end

    def package_extension
      "deb"
    end

    def architecture_extension
      if java.lang.System.getProperty("os.arch") == "amd64"
        "amd64"
      else
        "arm64"
      end
    end

    def install(package)
      cmd = sudo_exec!("dpkg -i --force-confnew #{package}")
      if cmd.exit_status != 0
        raise InstallException.new(cmd.stderr.to_s)
      end
    end

    def uninstall(package)
      sudo_exec!("dpkg -r #{package}")
      sudo_exec!("dpkg --purge #{package}")
    end

    def removed?(package)
      stdout = ""
      cmd = sudo_exec!("dpkg -s #{package}")
      stdout = cmd.stderr
      (
        stdout.match(/^Package `#{package}' is not installed and no info is available.$/) ||
        stdout.match(/^dpkg-query: package '#{package}' is not installed and no information is available$/)
      )
    end
  end
end
