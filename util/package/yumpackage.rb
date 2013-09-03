module MCollective
  module Util
    module Package
      class YumPackage<Base
        def install
          return call_action(:install)
        end

        def update
          return call_action(:update)
        end

        def uninstall
          return call_action(:remove)
        end

        #def purge
        #  return call_action(:remove)
        #end

        # Status returns a hash of package properties
        def status
          return call_action(:status)
        end

        # Calls and cleans up the yum provider
        def call_action(action)
          require 'json'
          yumhelper = File::join(File::dirname(__FILE__), "yumHelper.py")
          raise 'Cannot find yumHelper.py' unless File.exists?(yumhelper)
          result = {:exitcode => nil,
                    :output => ""}

          name = @package
          opts = @options
          cmd = Shell.new("#{yumhelper} --#{action} #{name}", :stdout => result[:output])
          cmd.runcommand
          result[:exitcode] = cmd.status.exitstatus
  
          raise "yumHelper.py failed, exit code was #{result[:exitcode]}" unless result[:exitcode] == 0
          r = {}
          JSON.parse(result[:output]).each do |k, v|
            r[:"#{k}"] = v
            if r[:status].is_a?(Hash)
                h = {}
                r[:status].each do |x ,y|
                    h[:"#{x}"] = y
                end
                r[:status] = h 
            end
     	  end
          return r
        end
      end
    end
  end
end
