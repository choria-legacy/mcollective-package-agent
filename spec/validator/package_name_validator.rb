#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'validator', 'package_name.rb')

module MCollective
  module Validator
    describe Package_nameValidator do
      describe '#validate' do
        it 'should validate a valid package name' do
          Package_nameValidator.validate('rspec')
          Package_nameValidator.validate('rspec1')
          Package_nameValidator.validate('rspec-package')
          Package_nameValidator.validate('rspec-package-1')
          Package_nameValidator.validate('rspec.package')
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
