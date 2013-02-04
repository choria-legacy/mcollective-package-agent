module MCollective
  class Application
    class Package<MCollective::Application
      description "Install, uninstall, update, purge and perform other actions to packages"

      usage <<-END_OF_USAGE
mco package [OPTIONS] [FILTERS] <ACTION> <PACKAGE>
Usage: mco package <PACKAGE> <install|uninstall|purge|update|status>

The ACTION can be one of the following:

    install    - install PACKAGE
    uninstall  - uninstall PACKAGE
    purge      - uninstall PACKAGE and purge related config files
    update     - update PACKAGE
    status     - determine whether PACKAGE is installed and report its version
END_OF_USAGE

      option :yes,
             :arguments   => ["--yes", "-y"],
             :description => "Assume yes on any prompts",
             :type        => :bool

      def handle_message(action, message, *args)
        messages = {1 => 'Please specify package name and action',
                    2 => "Action has to be one of %s",
                    3 => "Do you really want to operate on packages unfiltered? (y/n): "}
        send(action, messages[message] % args)
      end

      def post_option_parser(configuration)
        if ARGV.size < 2
          handle_message(:raise, 1)
        else
          action = ARGV.shift
          package = ARGV.shift

          action_list = ['install', 'uninstall', 'purge', 'update', 'status']

          unless action_list.include?(action)
            handle_message(:raise, 2, action_list.join(', '))
          end

          configuration[:package] = package
          configuration[:action] = action
        end
      end

      def validate_configuration(configuration)
        unless configuration[:action] == 'status'
          if Util.empty_filter?(options[:filter]) && !configuration[:yes]
            handle_message(:print, 3)

            STDOUT.flush
            exit(1) unless STDIN.gets.strip.match(/^(?:y|yes)$/i)
          end
        end
      end

      def main
        pkg = rpcclient("package")
        pkg_result = pkg.send(configuration[:action], :package => configuration[:package])

        sender_width = pkg_result.map{|s| s[:sender]}.map{|s| s.length}.max + 3
        pattern = "%%%ds: %%s" % sender_width

        pkg_result.each do |result|
          if result[:statuscode] == 0
            if pkg.verbose
              puts(pattern % [result[:sender], result[:data][:ensure]])
            else
              if configuration[:action] == 'status'
                if result[:data][:ensure] == 'absent'
                  status = 'absent'
                else
                  status = "%s-%s.%s" % [result[:data][:name], result[:data][:ensure], result[:data][:arch]]
                end
                puts(pattern % [result[:sender], status])
              end
            end
          else
            puts(pattern % [result[:sender], result[:statusmsg]])
          end
        end

        puts

        printrpcstats :summarize => true, :caption => "%s Package results" % configuration[:action]
        halt(pkg.stats)
      end
    end
  end
end
