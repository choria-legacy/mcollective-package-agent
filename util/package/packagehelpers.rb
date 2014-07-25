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

        def self.packagemanager
          if File.exists?('/usr/bin/yum')
            return :yum
          elsif File.exists?('/usr/bin/apt-get')
            return :apt
          elsif File.exists?('/usr/bin/zypper')
            return :zypper
          end
        end

        def self.checkupdates
          manager = packagemanager
          if manager == :yum
            return yum_checkupdates
          elsif manager == :apt
            return apt_checkupdates
          elsif manager == :zypper
            return zypper_checkupdates
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

        def self.zypper_checkupdates(output = "")
          raise 'Cannot find zypper at /usr/bin/zypper' unless File.exists?('/usr/bin/zypper')

          result = {:exitcode => nil,
                    :output => output,
                    :outdated_packages => [],
                    :package_manager => 'zypper'}

          cmd = Shell.new('/usr/bin/zypper -q list-updates', :stdout => result[:output])
          cmd.runcommand
          result[:exitcode] = cmd.status.exitstatus

          result[:output].each_line do |line|
            next if line =~ /^S\s/
            next if line =~ /^--/
            sup,repo,name,cur_ver,new_ver,arch = line.split('|')
            if repo && name && new_ver
              result[:outdated_packages] << {:package => name.strip,
                                             :version => new_ver.strip,
                                             :repo    => repo.strip}
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
