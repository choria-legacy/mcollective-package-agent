#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../../', 'util', 'package', 'base.rb')

module MCollective
  module Util
    module Package
      describe Base do
        let(:base) { Base.new('rspec', {:rkey => 'rvalue'}) }
        describe '#initialize' do
          it 'should set the package name and the options hash' do
            base.package.should == 'rspec'
            base.options.should == {:rkey => 'rvalue'}
          end
        end

        describe 'install' do
          it 'should raise an error if called' do
            expect{
              base.install
            }.to raise_error 'error. MCollective::Util::Package::Base does not implement #install'
          end
        end

        describe 'uninstall' do
          it 'should raise an error if called' do
            expect{
              base.uninstall
            }.to raise_error 'error. MCollective::Util::Package::Base does not implement #uninstall'
          end
        end

        describe 'purge' do
          it 'should raise an error if called' do
            expect{
              base.purge
            }.to raise_error 'error. MCollective::Util::Package::Base does not implement #purge'
          end
        end

        describe 'update' do
          it 'should raise an error if called' do
            expect{
              base.update
            }.to raise_error 'error. MCollective::Util::Package::Base does not implement #update'
          end
        end

        describe 'status' do
          it 'should raise an error if called' do
            expect{
              base.status
            }.to raise_error 'error. MCollective::Util::Package::Base does not implement #status'
          end
        end
      end
    end
  end
end
