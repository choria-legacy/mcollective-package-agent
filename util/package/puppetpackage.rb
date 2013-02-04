module MCollective
  module Util
    module Package
      class PuppetPackage<Base
        def install
          unless absent?
            return {:status => status, :msg => 'Package is already installed'}
          else
            return {:output => call_action(:install), :status => status}
          end
        end

        def update
          if absent?
            return {:status => status, :msg => 'Package is not present on the system'}
          else
            return {:output => call_action(:update), :status => status}
          end
        end

        def uninstall
          if absent?
            return {:status => status, :msg => 'Package is not present on the system'}
          else
            return {:output =>call_action(:uninstall), :status => status}
          end
        end

        def purge
          if absent?
            return {:status => status, :msg => 'Package is not present on the system'}
          else
            return {:output => call_action(:purge), :status => status}
          end
        end

        # Status returns a hash of package properties
        def status
          provider.properties
        end

        private
        # Creates a Puppet package provider
        def provider
          require 'puppet'
          @provider ||= Puppet::Type.type(:package).new({:name => @package}.merge(@options)).provider
        end

        # Check whether the package is abent or present
        def absent?
          [:absent, :purged].include?(provider.properties[:ensure])
        end

        # Calls and cleans up the Puppet provider
        def call_action(action)
          output = provider.send(action)
          provider.flush
          return output
        end
      end
    end
  end
end
