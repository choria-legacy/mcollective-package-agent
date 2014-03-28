#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../../', 'util', 'package', 'base.rb')
require File.join(File.dirname(__FILE__), '../../../', 'util', 'package', 'puppetpackage.rb')

module MCollective
  module Util
    module Package
      describe PuppetPackage do
        let(:package) { PuppetPackage.new('rspec', {}) }
        let(:provider) { mock }
        let(:status) { {:key => 'value'} }

        before do
          package.stubs(:provider).returns(provider)
        end

        describe '#install' do
          it 'should install the package and return the status' do
            package.stubs(:absent?).returns(true)
            package.expects(:status).returns(status)
            package.expects(:call_action).with(:install).returns('the output')

            result = package.install
            result[:status].should == status
            result[:output].should == 'the output'
          end

          it 'should return a failure message and status if the package is already installed' do
            package.stubs(:absent?).returns(false)
            package.expects(:status).returns(status)

            result = package.install
            result[:status].should == status
            result[:msg].should == 'Package is already installed'
          end
        end

        describe '#update' do
          it 'should update the package and return the status' do
            package.stubs(:absent?).returns(false)
            package.expects(:status).returns(status)
            package.expects(:call_action).with(:update).returns('the output')

            result = package.update
            result[:status].should == status
            result[:output].should == 'the output'
          end

          it 'should return a failure message and status if the package is absent' do
            package.stubs(:absent?).returns(true)
            package.expects(:status).returns(status)

            result = package.update
            result[:status].should == status
            result[:msg].should == 'Package is not present on the system'
          end
        end

        describe '#uninstall' do
          it 'should uninstall the package and return the status' do
            package.stubs(:absent?).returns(false)
            package.expects(:status).returns(status)
            package.expects(:call_action).with(:uninstall).returns('the output')

            result = package.uninstall
            result[:status].should == status
            result[:output].should == 'the output'
          end

          it 'should return a failure message and status if the package is absent' do
            package.stubs(:absent?).returns(true)
            package.expects(:status).returns(status)

            result = package.uninstall
            result[:status].should == status
            result[:msg].should == 'Package is not present on the system'
          end
        end

        describe '#purge' do
          it 'should purge the package and return the status' do
            package.stubs(:absent?).returns(false)
            package.expects(:status).returns(status)
            package.expects(:call_action).with(:purge).returns('the output')

            result = package.purge
            result[:status].should == status
            result[:output].should == 'the output'
          end

          it 'should return a failure message and status if the package is absent' do
            package.stubs(:absent?).returns(true)
            package.expects(:status).returns(status)

            result = package.purge
            result[:status].should == status
            result[:msg].should == 'Package is not present on the system'
          end
        end

        describe '#status' do
          it 'should return the package status' do
            provider.expects(:properties)
            package.status
          end
        end

        describe '#provider' do
          class Puppet; class Type; end; end

          it 'should load the provider only once' do
            package.unstub(:provider)
            package.stubs(:require)

            type = mock
            type.stubs(:new).returns(type)
            Puppet::Type.stubs(:type).returns(type).once
            type.stubs(:provider).returns(provider).once

            package.send(:provider)
            package.send(:provider)
          end

          it 'should load the provider instances on windows' do
            package.unstub(:provider)
            package.stubs(:require)
            type = mock
            instance = mock
            provider_class = mock
            provider_class.expects(:to_s).returns('Puppet::Type::Package::ProviderWindows')
            provider_class.expects(:instances).returns([instance])
            instance.stubs(:name).returns("rspec")
            instance.stubs(:package).returns("rspec")
            type.stubs(:new).returns(type)
            Puppet::Type.stubs(:type).returns(type)
            type.stubs(:provider).returns(provider)
            Util.stubs(:windows?).returns(true)
            provider.stubs(:class).returns(provider_class)
            provider.expects(:package=).with("rspec")

            package.send(:provider)
          end

          it 'should return the provider object' do
            package.unstub(:provider)
            package.stubs(:require)

            type = mock
            type.stubs(:new).returns(type)
            Puppet::Type.stubs(:type).returns(type)
            type.stubs(:provider).returns(provider)

            package.send(:provider).should == provider

          end
        end

        describe '#absent?' do
          it 'should return true if the package is absent' do
            provider.stubs(:properties).returns(:ensure => :absent)
            package.send(:absent?).should be_true
          end

          it 'should return false if the package is present' do
            provider.stubs(:properties).returns(:ensure => 'xx-xx-xx')
            package.send(:absent?).should be_false
          end

        end

        describe '#call_action' do
          it 'should call the correct provider action' do
            provider.expects(:send).with('rspec').returns('Called action')
            provider.expects(:flush)
            result = package.send(:call_action, 'rspec')
            result.should == 'Called action'
          end
        end
      end
    end
  end
end
