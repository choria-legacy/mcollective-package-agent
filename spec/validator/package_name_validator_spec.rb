#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'validator', 'package_name.rb')

module MCollective
  module Validator
    describe Package_nameValidator do
      describe '#validate' do
        it 'should validate a valid package name without errors' do
          expect{
            Package_nameValidator.validate('rspec')
          }.to_not raise_error

          expect{
            Package_nameValidator.validate('rspec1')
          }.to_not raise_error

          expect{
            Package_nameValidator.validate('rspec-package')
          }.to_not raise_error

          expect{
            Package_nameValidator.validate('rspec-package-1')
          }.to_not raise_error

          expect{
            Package_nameValidator.validate('rspec.package')
          }.to_not raise_error
        end
        it 'should fail on a invalid package name' do
          expect{
            Package_nameValidator.validate('rspec!')
          }.to raise_error
        end
      end
    end
  end
end
