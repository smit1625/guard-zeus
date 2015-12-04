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
      Compat::UI.info "Guard::Zeus --> Other guards: #{Guard.plugins.inspect}"
      Compat::UI.info "Guard::Zeus --> State: #{Guard.state.inspect}"
      running_zeus_plugins = Guard.state.session.plugins.select do |p|
        plugin_options = p.options if p.respond_to?(:options) && p.options.any?
        plugin_options ||= p.runner.options if p.respond_to?(:runner) && p.runner.respond_to?(:options)
        plugin_options[:zeus]
      end
      if running_zeus_plugins.any?
      end
      runner.kill_zeus
    end
  end
end
