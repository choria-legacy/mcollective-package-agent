module MCollective
  module Util
    module Package
      class PackageHelpers

        def self.yum_clean(clean_mode)
          raise "Cannot find yum at /usr/bin/yum" unless File.exists?("/usr/bin/yum")
          result = {:exitcode => nil,
                    :output => ""}

          if ["all", "headers", "packages", "metadata", "dbcache", "plugins", "expire-cache"].include?(clean_mode)
            cmd = Shell.new("/usr/bin/yum clean #{clean_mode}", :stdout => result[:output])
            cmd.runcommand
            result[:exitcode] = cmd.status.exitstatus
          else
            raise "Unsupported yum clean mode: %s" % clean_mode
          end

          raise "Yum clean failed, exit code was #{result[:exitcode]}" unless result[:exitcode] == 0
          return result
        end

        def self.apt_update
          raise 'Cannot find apt-get at /usr/bin/apt-get' unless File.exists?('/usr/bin/apt-get')
          result = {:exitcode => nil,
                    :output => ""}

          cmd = Shell.new('/usr/bin/apt-get update', :stdout => result[:output])
          cmd.runcommand
          result[:exitcode] = cmd.status.exitstatus

          raise "apt-get update failed, exit code was #{result[:exitcode]}" unless result[:exitcode] == 0
          return result
        end

        def self.apt_clear_packages
          raise 'Cannot find dpkg at /usr/bin/dpkg' unless File.exists?('/usr/bin/dpkg')
          result = {:exitcode => nil,
                    :output => ""}

          cmd = Shell.new("/usr/bin/dpkg -l | grep '^iF' | awk '{ print $2}' | xargs sudo apt-get -y remove", :stdout => result[:output])
          cmd.runcommand
          result[:exitcode] = cmd.status.exitstatus

          raise "dpkg clean failed, exit code was #{result[:exitcode]}" unless result[:exitcode] == 0
          return result
        end

        def self.packagemanager
          if File.exists?('/usr/bin/yum')
            return :yum
          elsif File.exists?('/usr/bin/apt-get')
            return :apt
          end
        end

        def self.checkupdates
          manager = packagemanager
          if manager == :yum
            return yum_checkupdates
          elsif manager == :apt
            return apt_checkupdates
          else
            raise 'Cannot find a compatible package system to check updates'
          end
        end

        def self.yum_checkupdates(output = "")
          raise 'Cannot find yum at /usr/bin/yum' unless File.exists?('/usr/bin/yum')

          result = {:exitcode => nil,
                    :output => output,
                    :outdated_packages => [],
                    :package_manager => 'yum'}

          cmd = Shell.new('/usr/bin/yum -q check-update', :stdout => result[:output])
          cmd.runcommand
          result[:exitcode] = cmd.status.exitstatus

          result[:output].strip.each_line do |line|
            break if line =~ /^Obsoleting\sPackages/i

            pkg, ver, repo = line.split
            if pkg && ver && repo
              result[:outdated_packages] << {:package => pkg.strip,
                                             :version => ver.strip,
                                             :repo => repo.strip}
            end
          end

          result
        end

        def self.apt_checkupdates(output = "")
          raise 'Cannot find apt-get at /usr/bin/apt-get' unless File.exists?("/usr/bin/apt-get")

          result = {:exitcode => nil,
                    :output => output,
                    :outdated_packages => [],
                    :package_manager => 'apt'}

          cmd = Shell.new("/usr/bin/apt-get --simulate dist-upgrade", :stdout => result[:output])
          cmd.runcommand
          result[:exitcode] = cmd.status.exitstatus

          raise "Apt check-update failed, exit code was #{result[:exitcode]}" unless result[:exitcode] == 0

          result[:output].each_line do |line|
            next unless line =~ /^Inst/

            # Inst emacs23 [23.1+1-4ubuntu7] (23.1+1-4ubuntu7.1 Ubuntu:10.04/lucid-updates) []
            if line =~ /Inst (.+?) \[.+?\] \((.+?)\s(.+?)\)/
              result[:outdated_packages] << {:package => $1.strip,
                                             :version => $2.strip,
                                             :repo => $3.strip}
            end
          end

          result
        end
      end
    end
  end
end
