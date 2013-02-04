#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'agent', 'package.rb')
require File.join(File.dirname(__FILE__), '../../', 'data', 'package_data.rb')

module MCollective
  module Data
    describe Package_data do
      before do
        @data_file = File.join(File.dirname(__FILE__), '../../', 'data', 'package_data.rb')
        @data = MCollective::Test::DataTest.new("package_data", :data_file => @data_file).plugin
      end

      it 'should return all the data' do
        result_set = {:epoch => 1234,
                      :arch => 'x86',
                      :ensure => 'present',
                      :version => 'xx-xx-xx',
                      :provider => 'yum',
                      :name => 'rspecpackage',
                      :release => 2}

        Agent::Package.expects(:do_pkg_action).returns(result_set)
        @data.query_data('rspec').should == result_set
      end

      it 'should log an error mesage if the package status cannot be determined' do
        Agent::Package.stubs(:do_pkg_action).raises("error")
        Log.expects(:warn).with("Could not get status for package 'rspec': error")
        @data.query_data('rspec')
      end
    end
  end
end
