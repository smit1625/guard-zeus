require "listen"

require "guard/notifier"
require "guard/interactor"
require "guard/runner"
require "guard/dsl_describer"

require "guard/internals/state"

module Guard
  module Commander
    def start(options={})
      puts "CUSTOM COMMANDER STARTING UP!"
      super
    end
  end
  extend Commander
end
