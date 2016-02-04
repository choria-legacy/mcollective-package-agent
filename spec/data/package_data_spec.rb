#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'data', 'package_data.rb')
require File.join(File.dirname(__FILE__), '../../', 'agent', 'package.rb')

module MCollective
  module Data
    describe Package_data do
      describe '#query_data' do
        let(:plugin){Package_data.new}

        before do
          @ddl = mock('ddl')
          @ddl.stubs(:dataquery_interface).returns({:output => {}})
          @ddl.stubs(:meta).returns({:timeout => 1})
          DDL.stubs(:new).returns(@ddl)
        end

        it 'should call package action with the correct arguments' do
          Agent::Package.expects(:do_pkg_action).with('rspec', 'status', {})
          plugin.query_data('rspec')
        end

        it 'should display an error message if package status cannot be determined' do
          val = {}
          Agent::Package.expects(:do_pkg_action).with('rspec', 'status', val).raises('error')
          MCollective::Log.expects(:warn).with("Could not get status for package rspec: error")
          plugin.query_data('rspec')
        end
      end
    end
  end
end
