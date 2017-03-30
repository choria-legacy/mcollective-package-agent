#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../../', 'util', 'package', 'packagehelpers.rb')

module MCollective
  module Util
    module Package
      describe PackageHelpers do
        describe "#yum_clean" do
          it 'should raise if the yum binary cannot be found' do
            File.expects(:exists?).with('/usr/bin/yum').returns(false)
            expect{
              PackageHelpers.yum_clean('all')
            }.to raise_error('Cannot find yum at /usr/bin/yum')
          end

          it 'should raise if an unsupported clean mode is supplied' do
            File.expects(:exists?).with('/usr/bin/yum').returns(true)
            expect{
              PackageHelpers.yum_clean('rspec')
            }.to raise_error('Unsupported yum clean mode: rspec')
          end

          it 'should raise if the yum command failed' do
            File.stubs(:exists?).with('/usr/bin/yum').returns(true)
            shell = mock
            status = mock
            Shell.expects(:new).with('/usr/bin/yum clean all', :stdout => '').returns(shell)
            shell.stubs(:runcommand)
            shell.stubs(:status).returns(status)
            status.stubs(:exitstatus).returns(-1)

            expect{
              PackageHelpers.yum_clean('all')
            }.to raise_error('Yum clean failed, exit code was -1')
          end

          it 'should clean with the correct clean mode' do
            File.stubs(:exists?).with('/usr/bin/yum').returns(true)
            shell = mock
            status = mock
            shell.stubs(:runcommand)
            shell.stubs(:status).returns(status)
            status.stubs(:exitstatus).returns(0)

            ['all', 'headers', 'packages', 'metadata', 'dbcache', 'plugins', 'expire-cache'].each do |mode|
              Shell.expects(:new).with("/usr/bin/yum clean #{mode}", :stdout => "").returns(shell)
              result = PackageHelpers.yum_clean(mode)
              result.should == {:exitcode => 0, :output => ""}
            end
          end
        end

        describe "#apt_update" do
          it 'should raise if the apt-get binary cannot be found' do
            File.expects(:exists?).with('/usr/bin/apt-get').returns(false)
            expect{
              PackageHelpers.apt_update
            }.to raise_error('Cannot find apt-get at /usr/bin/apt-get')
          end

          it 'should raise if the apt-get command failed' do
            File.expects(:exists?).with('/usr/bin/apt-get').returns(true)
            shell = mock
            status = mock
            shell.stubs(:runcommand)
            shell.stubs(:status).returns(status)
            status.stubs(:exitstatus).returns(-1)
            Shell.expects(:new).with('/usr/bin/apt-get update', :stdout => "").returns(shell)

            expect{
              PackageHelpers.apt_update
            }.to raise_error 'apt-get update failed, exit code was -1'
          end

          it 'should perform the update' do
            File.expects(:exists?).with('/usr/bin/apt-get').returns(true)
            shell = mock
            status = mock
            shell.stubs(:runcommand)
            shell.stubs(:status).returns(status)
            status.stubs(:exitstatus).returns(0)
            Shell.expects(:new).with('/usr/bin/apt-get update', :stdout => "").returns(shell)

            result = PackageHelpers.apt_update
            result.should == {:exitcode => 0, :output => ""}
          end

        end

        describe "#packagemanager" do
          it 'should return yum if yum is present on the system' do
            File.expects(:exists?).with('/usr/bin/yum').returns(true)
            PackageHelpers.packagemanager.should == :yum
          end

          it 'should return apt if apt-get is present on the system' do
            File.expects(:exists?).with('/usr/bin/yum').returns(false)
            File.expects(:exists?).with('/usr/bin/apt-get').returns(true)
            PackageHelpers.packagemanager.should == :apt
          end

          it 'should return zypper if zypper is present on the system' do
            File.expects(:exists?).with('/usr/bin/yum').returns(false)
            File.expects(:exists?).with('/usr/bin/apt-get').returns(false)
            File.expects(:exists?).with('/usr/bin/zypper').returns(true)
            PackageHelpers.packagemanager.should == :zypper
          end
        end

        describe "count" do
          it 'should call #rpm_count if yum is present on the system' do
            PackageHelpers.expects(:packagemanager).returns(:yum)
            PackageHelpers.expects(:rpm_count)
            PackageHelpers.count
          end

          it 'should call #dpkg_count if apt is present on the system' do
            PackageHelpers.expects(:packagemanager).returns(:apt)
            PackageHelpers.expects(:dpkg_count)
            PackageHelpers.count
          end

          it 'should fail if no compatible package manager is present on the system' do
            PackageHelpers.expects(:packagemanager).returns(nil)

            expect{
              PackageHelpers.count
            }.to raise_error 'Cannot find a compatible package system to count packages'
          end
        end

       describe "md5" do
          it 'should call #rpm_md5 if yum is present on the system' do
            PackageHelpers.expects(:packagemanager).returns(:yum)
            PackageHelpers.expects(:rpm_md5)
            PackageHelpers.md5
          end

          it 'should call #dpkg_md5 if apt is present on the system' do
            PackageHelpers.expects(:packagemanager).returns(:apt)
            PackageHelpers.expects(:dpkg_md5)
            PackageHelpers.md5
          end

          it 'should fail if no compatible package manager is present on the system' do
            PackageHelpers.expects(:packagemanager).returns(nil)

            expect{
              PackageHelpers.md5
            }.to raise_error 'Cannot find a compatible package system to get a md5 of the package list'
          end
        end

        describe "rpm_count" do
          it 'should raise if rpm cannot be found on the system' do
            File.expects(:exists?).with('/usr/bin/rpm').returns(false)

            expect{
              PackageHelpers.rpm_count
            }.to raise_error 'Cannot find rpm at /usr/bin/rpm'
          end

          it 'should raise if the rpm command failed' do
            File.expects(:exists?).with('/usr/bin/rpm').returns(true)
            shell = mock
            status = mock
            shell.stubs(:runcommand)
            shell.stubs(:status).returns(status)
            status.stubs(:exitstatus).returns(-1)
            Shell.expects(:new).with('/usr/bin/rpm -qa', :stdout => "").returns(shell)

            expect{
              PackageHelpers.rpm_count
            }.to raise_error 'rpm command failed, exit code was -1'
          end


          it 'should return the count of packages' do
            output = "package1-1.1.1.el7.x86_64
                      package2 2.2.2.el7.noarch
                      package3 3.3.3.el7.x86_64"

            File.expects(:exists?).with('/usr/bin/rpm').returns(true)
            shell = mock
            status = mock
            Shell.stubs(:new).with('/usr/bin/rpm -qa', :stdout => output).returns(shell)
            shell.stubs(:runcommand)
            shell.stubs(:stdout).returns(output)
            shell.expects(:status).returns(status)
            status.stubs(:exitstatus).returns(0)

            result = PackageHelpers.rpm_count(output)
            result.should == {:exitcode => 0, :output => "3"}
          end
        end

        describe "rpm_md5" do
          it 'should raise if rpm cannot be found on the system' do
            File.expects(:exists?).with('/usr/bin/rpm').returns(false)

            expect{
              PackageHelpers.rpm_md5
            }.to raise_error 'Cannot find rpm at /usr/bin/rpm'
          end

          it 'should raise if the rpm command failed' do
            File.expects(:exists?).with('/usr/bin/rpm').returns(true)
            shell = mock
            status = mock
            shell.stubs(:runcommand)
            shell.stubs(:status).returns(status)
            status.stubs(:exitstatus).returns(-1)
            Shell.expects(:new).with('/usr/bin/rpm -qa', :stdout => "").returns(shell)

            expect{
              PackageHelpers.rpm_md5
            }.to raise_error 'rpm command failed, exit code was -1'
          end


          it 'should return the md5 of packages' do
            output = "package1-1.1.1.el7.x86_64
                      package2 2.2.2.el7.noarch
                      package3 3.3.3.el7.x86_64"

            File.expects(:exists?).with('/usr/bin/rpm').returns(true)
            shell = mock
            status = mock
            Shell.stubs(:new).with('/usr/bin/rpm -qa', :stdout => output).returns(shell)
            shell.stubs(:runcommand)
            shell.stubs(:stdout).returns(output)
            shell.expects(:status).returns(status)
            status.stubs(:exitstatus).returns(0)

            result = PackageHelpers.rpm_md5(output)
            result.should == {:exitcode => 0, :output => "f484823d241bd4315ac8741df15a91af"}
          end
        end

        describe "dpkg_count" do
          it 'should raise if dpkg cannot be found on the system' do
            File.expects(:exists?).with('/usr/bin/dpkg').returns(false)

            expect{
              PackageHelpers.dpkg_count
            }.to raise_error 'Cannot find dpkg at /usr/bin/dpkg'
          end

         it 'should raise if the dpkg command failed' do
            File.expects(:exists?).with('/usr/bin/dpkg').returns(true)
            shell = mock
            status = mock
            shell.stubs(:runcommand)
            shell.stubs(:status).returns(status)
            status.stubs(:exitstatus).returns(-1)
            Shell.expects(:new).with('/usr/bin/dpkg --list', :stdout => "").returns(shell)

            expect{
              PackageHelpers.dpkg_count
            }.to raise_error 'dpkg command failed, exit code was -1'
          end


          it 'should return the count of packages' do
            output = "Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name                                                  Version                                       Architecture Description
+++-=====================================================-=============================================-============-================================================================================
ii  a11y-profile-manager-indicator                        0.1.10-0ubuntu3                               amd64        Accessibility Profile Manager - Unity desktop indicator
rc  abiword                                               3.0.1-6ubuntu0.16.04.1                        amd64        efficient, featureful word processor with collaboration
ii  abiword-common                                        3.0.1-6ubuntu0.16.04.1                        all          efficient, featureful word processor with collaboration -- common files
ii  account-plugin-aim                                    3.12.11-0ubuntu3                              amd64        Messaging account plugin for AIM"

            File.expects(:exists?).with('/usr/bin/dpkg').returns(true)
            shell = mock
            status = mock
            Shell.stubs(:new).with('/usr/bin/dpkg --list', :stdout => output).returns(shell)
            shell.stubs(:runcommand)
            shell.stubs(:stdout).returns(output)
            shell.expects(:status).returns(status)
            status.stubs(:exitstatus).returns(0)

            result = PackageHelpers.dpkg_count(output)
            result.should == {:exitcode => 0, :output => "3"}
          end
        end

        describe "dpkg_md5" do
          it 'should raise if dpkg cannot be found on the system' do
            File.expects(:exists?).with('/usr/bin/dpkg').returns(false)

            expect{
              PackageHelpers.dpkg_md5
            }.to raise_error 'Cannot find dpkg at /usr/bin/dpkg'
          end

         it 'should raise if the dpkg command failed' do
            File.expects(:exists?).with('/usr/bin/dpkg').returns(true)
            shell = mock
            status = mock
            shell.stubs(:runcommand)
            shell.stubs(:status).returns(status)
            status.stubs(:exitstatus).returns(-1)
            Shell.expects(:new).with('/usr/bin/dpkg --list', :stdout => "").returns(shell)

            expect{
              PackageHelpers.dpkg_md5
            }.to raise_error 'dpkg command failed, exit code was -1'
          end


          it 'should return the md5 of packages' do
            output = "Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name                                                  Version                                       Architecture Description
+++-=====================================================-=============================================-============-================================================================================
ii  a11y-profile-manager-indicator                        0.1.10-0ubuntu3                               amd64        Accessibility Profile Manager - Unity desktop indicator
rc  abiword                                               3.0.1-6ubuntu0.16.04.1                        amd64        efficient, featureful word processor with collaboration
ii  abiword-common                                        3.0.1-6ubuntu0.16.04.1                        all          efficient, featureful word processor with collaboration -- common files
ii  account-plugin-aim                                    3.12.11-0ubuntu3                              amd64        Messaging account plugin for AIM"

            File.expects(:exists?).with('/usr/bin/dpkg').returns(true)
            shell = mock
            status = mock
            Shell.stubs(:new).with('/usr/bin/dpkg --list', :stdout => output).returns(shell)
            shell.stubs(:runcommand)
            shell.stubs(:stdout).returns(output)
            shell.expects(:status).returns(status)
            status.stubs(:exitstatus).returns(0)

            result = PackageHelpers.dpkg_md5(output)
            result.should == {:exitcode => 0, :output => "9608a4c69c0dd39b2ceb2cfafc36d67f"}
          end
        end

        describe "checkupdates" do
          it 'should call #yum_checkupdates if yum is present on the system' do
            PackageHelpers.expects(:packagemanager).returns(:yum)
            PackageHelpers.expects(:yum_checkupdates)
            PackageHelpers.checkupdates
          end

          it 'should call #apt_checkupdates if apt is present on the system' do
            PackageHelpers.expects(:packagemanager).returns(:apt)
            PackageHelpers.expects(:apt_checkupdates)
            PackageHelpers.checkupdates
          end

          it 'should call #zypper_checkupdates if zypper is present on the system' do
            PackageHelpers.expects(:packagemanager).returns(:zypper)
            PackageHelpers.expects(:zypper_checkupdates)
            PackageHelpers.checkupdates
          end

          it 'should fail if no compatible package manager is present on the system' do
            PackageHelpers.expects(:packagemanager).returns(nil)

            expect{
              PackageHelpers.checkupdates
            }.to raise_error 'Cannot find a compatible package system to check updates'
          end
        end

        describe "yum_checkupdates" do
          it 'should raise if yum cannot be found on the system' do
            File.expects(:exists?).with('/usr/bin/yum').returns(false)

            expect{
              PackageHelpers.yum_checkupdates
            }.to raise_error 'Cannot find yum at /usr/bin/yum'
          end

          it 'should return the list of outdated packages' do
            output = "package1 1.1.1 rspecrepo
                      package2 2.2.2 rspecrepo"

            File.expects(:exists?).with('/usr/bin/yum').returns(true)
            shell = mock
            status = mock
            Shell.stubs(:new).with('/usr/bin/yum -q check-update', :stdout => output).returns(shell)
            shell.stubs(:runcommand)
            shell.expects(:status).returns(status)
            status.stubs(:exitstatus).returns(0)

            result = PackageHelpers.yum_checkupdates(output)
            result[:exitcode].should == 0
            result[:output].should == output
            result[:package_manager] == 'yum'
            result[:outdated_packages].should == [ {:package => 'package1', :version => '1.1.1', :repo => 'rspecrepo'},
                                                   {:package => 'package2', :version => '2.2.2', :repo => 'rspecrepo'}]
          end
        end

        describe "zypper_checkupdates" do
          it 'should raise if zypper cannot be foud on the system' do
            File.expects(:exists?).with('/usr/bin/zypper').returns(false)

            expect{
              PackageHelpers.zypper_checkupdates
            }.to raise_error 'Cannot find zypper at /usr/bin/zypper'
          end

          it 'should return the list of outdated packages' do
            output = "S | Repository         | Name                            | Current Version        | Available Version        | Arch
                      --+--------------------+---------------------------------+------------------------+--------------------------+-------
                      v | Test_Repository    | Package1                        | 1.2.3-1                | 1.2.3-2                  | x86_64
                      v | Test_Repository    | Package2                        | 0.1.1-1                | 0.2.2-2                  | x86_64"

            File.expects(:exists?).with('/usr/bin/zypper').returns(true)
            shell = mock
            status = mock
            Shell.stubs(:new).with('/usr/bin/zypper -q list-updates', :stdout => output).returns(shell)
            shell.stubs(:runcommand)
            shell.expects(:status).returns(status)
            status.stubs(:exitstatus).returns(0)

            result = PackageHelpers.zypper_checkupdates(output)
            result[:exitcode].should == 0
            result[:output].should == output
            result[:package_manager] == 'zypper'
            result[:outdated_packages].should == [ {:package => 'Package1', :version => '1.2.3-2', :repo => 'Test_Repository'},
                                                   {:package => 'Package2', :version => '0.2.2-2', :repo => 'Test_Repository'}]
          end
        end

        describe "#apt_checkupdates" do
          it 'should raise if apt cannot be found on the system' do
            File.expects(:exists?).with('/usr/bin/apt-get').returns(false)

            expect{
              PackageHelpers.apt_checkupdates
            }.to raise_error 'Cannot find apt-get at /usr/bin/apt-get'
          end

          it 'should raise if the check-update command failed' do
            File.expects(:exists?).with('/usr/bin/apt-get').returns(true)
            shell = mock
            status = mock
            Shell.stubs(:new).with('/usr/bin/apt-get --simulate dist-upgrade', :stdout => '').returns(shell)
            shell.stubs(:runcommand)
            shell.expects(:status).returns(status)
            status.stubs(:exitstatus).returns(-1)

            expect{
              PackageHelpers.apt_checkupdates
            }.to raise_error 'Apt check-update failed, exit code was -1'
          end


          it 'should return the list of outdated packages' do
            output = "Inst package1 [23.1+1-4ubunto7] (1.1.1 rspecrepo)\nInst package2 [23.1+1-4ubunto7] (2.2.2 rspecrepo)"

            File.expects(:exists?).with('/usr/bin/apt-get').returns(true)
            shell = mock
            status = mock
            Shell.stubs(:new).with('/usr/bin/apt-get --simulate dist-upgrade', :stdout => output).returns(shell)
            shell.stubs(:runcommand)
            shell.expects(:status).returns(status)
            status.stubs(:exitstatus).returns(0)

            result = PackageHelpers.apt_checkupdates(output)
            result[:exitcode].should == 0
            result[:output].should == output
            result[:package_manager] == 'yum'
            result[:outdated_packages].should == [ {:package => 'package1', :version => '1.1.1', :repo => 'rspecrepo'},
                                                   {:package => 'package2', :version => '2.2.2', :repo => 'rspecrepo'}]
          end
        end
      end
    end
  end
end
