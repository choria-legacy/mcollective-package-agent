module MCollective
  module Data
    class Package_data<Base
      activate_when { PluginManager['package_agent'] }

      query do |package|
        begin
          Agent::Package.do_pkg_action(package, :status, result)
        rescue Exception => e
          Log.warn("Could not get status for package '%s': %s" % [package, e.to_s])
        end
      end
    end
  end
end

