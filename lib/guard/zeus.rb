require 'guard/compat/plugin'

module Guard
  class Zeus < Plugin
    autoload :Runner, 'guard/zeus/runner'
    attr_accessor :runner

    def initialize(options = {})
      super
      @runner = Runner.new(options)
    end

    def start
      runner.kill_zeus(true)
      runner.launch_zeus('Start')
    end

    def reload
      runner.kill_zeus(true)
      runner.launch_zeus('Reload')
    end

    def run_all
      runner.run_all
    end

    def run_on_modifications(paths)
      runner.run(paths)
    end

    def stop
      runner.kill_zeus
    end
  end
end
