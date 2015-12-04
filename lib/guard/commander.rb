require "listen"

require "guard/notifier"
require "guard/interactor"
require "guard/runner"
require "guard/dsl_describer"

require "guard/internals/state"

module Guard
  module Commander
    def self.included(base)
      base.class_eval do
        alias_method :original_start, :start
        def start(options={})
          puts 'CUSTOM COMMANDER STARTING UP!'
          original_start
        end
      end
    end
  end
  extend Commander
end
