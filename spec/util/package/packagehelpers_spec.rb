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
          it 'should raise if th eapt-get binary cannot be found' do
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
