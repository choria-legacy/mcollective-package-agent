#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'application', 'package.rb')

module MCollective
  class Application
    describe Package do
      before do
        application_file = File.join(File.dirname(__FILE__), '../../', 'application', 'package.rb')
        @app = MCollective::Test::ApplicationTest.new('package', :application_file => application_file).plugin
      end

      describe '#description' do
        it 'should have a description' do
          @app.should have_a_description
        end
      end

      describe '#post_option_parser' do
        it 'should fail if both an action and package are not supplied' do
          ARGV << 'rspec'
          expect{
            @app.post_option_parser({})
          }.to raise_error 'Please specify package name and action'

          ARGV.shift
          expect{
            @app.post_option_parser({})
          }.to raise_error 'Please specify package name and action'
        end

        it 'should fail on an unknown action' do
          ARGV << 'rspec'
          ARGV << 'rspec'

          expect{
            @app.post_option_parser({})
          }.to raise_error 'Action has to be one of install, uninstall, purge, update, status'
        end

        it 'should parse "action" "package" correctly' do
          config = {}

          ARGV << 'install'
          ARGV << 'rspec'

          @app.post_option_parser(config)
          config[:action].should == 'install'
          config[:package].should == 'rspec'
        end

        it 'should parse "package" "action" correctly' do
          config = {}

          ARGV << 'rspec'
          ARGV << 'install'

          @app.post_option_parser(config)
          config[:action].should == 'install'
          config[:package].should == 'rspec'
        end
      end

      describe '#validate_configuration' do
        it 'should prompt for confirmation if yes flag is unset and filter is empty' do
          Util.expects(:empty_filter?).returns(true)
          @app.stubs(:options).returns({:filter => {}})
          @app.expects(:handle_message).with(:print, 3)
          STDOUT.expects(:flush)
          STDIN.stubs(:gets).returns('y')
          @app.validate_configuration({})
        end

        it 'should exit if prompted and not answered yes' do
          Util.expects(:empty_filter?).returns(true)
          @app.stubs(:options).returns({:filter => {}})
          @app.expects(:handle_message).with(:print, 3)
          STDOUT.expects(:flush)
          STDIN.stubs(:gets).returns('n')
          @app.expects(:exit).with(1)
          @app.validate_configuration({})
        end

        it 'should not prompt if filter is not empty' do
          @app.stubs(:options).returns({:filter => {}})
          Util.expects(:empty_filter?).returns(false)
          @app.expects(:handle_message).never
          @app.validate_configuration({})
        end

        it 'should not prompt if yes flag is set' do
          @app.stubs(:options).returns({:filter => {}})
          Util.expects(:empty_filter?).returns(false)
          @app.expects(:handle_message).never
          @app.validate_configuration({:yes => true})
        end
      end

      describe '#main' do
        let(:pattern) { "%8s: %s" }
        let(:package) { mock }

        before do
          @app.expects(:printrpcstats)
          @app.expects(:halt)
          @app.expects(:rpcclient).returns(package)
          package.stubs(:stats)
        end

        it 'should display the correct verbose output' do
          @app.stubs(:configuration).returns({:action => 'uninstall', :package => 'rspec'})
          package.expects(:send).with('uninstall', :package => 'rspec').returns([{:sender => 'rspec',
                                                                                :statuscode => 0,
                                                                                :data => {:ensure => 'absent'}}])
          package.expects(:verbose).returns(true)
          @app.expects(:puts).with(pattern % ['rspec', 'absent'])
          @app.main
        end

        it 'should not output for install, update, uninstall and purge' do
          @app.stubs(:configuration).returns({:action => 'uninstall', :package => 'rspec'})
          package.expects(:send).with('uninstall', :package => 'rspec').returns([{:sender => 'rspec',
                                                                                :statuscode => 0,
                                                                                :data => {:ensure => 'absent'}}])
          package.expects(:verbose).returns(false)
          @app.expects(:puts).with(pattern % ['rspec', 'absent']).never
          @app.main
        end

        it 'should display the correct output for an absent package status' do
          @app.stubs(:configuration).returns({:action => 'status', :package => 'rspec'})
          package.expects(:send).with('status', :package => 'rspec').returns([{:sender => 'rspec',
                                                                               :statuscode => 0,
                                                                               :data => {:ensure => 'absent'}}])
          package.expects(:verbose).returns(false)
          @app.expects(:puts).with(pattern % ['rspec', 'absent'])
          @app.main
        end

        it 'should display the correct output for an installed package status' do
          @app.stubs(:configuration).returns({:action => 'status', :package => 'rspec'})
          package.expects(:send).with('status', :package => 'rspec').returns([{:sender => 'rspec',
                                                                                :statuscode => 0,
                                                                                :data => {:ensure => '2.1',
                                                                                          :arch => 'x86',
                                                                                          :name => 'rspec'}}])
          package.expects(:verbose).returns(false)
          @app.expects(:puts).with(pattern % ['rspec', 'rspec-2.1.x86'])
          @app.main
        end
      end
    end
  end
end
