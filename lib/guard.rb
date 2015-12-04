require "thread"
require "listen"

require "guard/config"
require "guard/deprecated/guard" unless Guard::Config.new.strict?
require "guard/internals/helpers"

require "guard/internals/debugging"
require "guard/internals/traps"
require "guard/internals/queue"

# TODO: remove this class altogether
require "guard/interactor"

module Guard
  # module Commander
    def self.included(base)
      puts 'Test 1'
      base.class_eval do
        puts 'Test 2'
        alias_method :original_start, :start
        def start(options={})
          puts 'CUSTOM COMMANDER STARTING UP!'
          original_start
        end
      end
    end
  # end
  # extend Commander
end
