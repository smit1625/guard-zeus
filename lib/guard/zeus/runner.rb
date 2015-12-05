# Needed for socket_file
require 'socket'
require 'tempfile'
require 'digest/md5'
require 'json'

require 'guard/compat/plugin'

module Guard
  class Zeus < Plugin
    class Runner
      MAX_WAIT_COUNT  = 10
      DEFAULT_OPTIONS = {
        run_all: true,
        exit_last: true,
        log_file: nil,
        pid_file: nil,
        timeout: 30
      }
      attr_reader :options

      def initialize(options = {})
        @zeus_pid = nil
        @options = DEFAULT_OPTIONS.merge(options)
        Compat::UI.info 'Guard::Zeus Initialized'
      end

      def kill_zeus(force=false)
        stop_zeus(force)
      end

      def launch_zeus(action)
        Compat::UI.info "#{action}ing Zeus", reset: true

        # check for a current .zeus.sock
        if File.exist? sockfile
          Compat::UI.info 'Guard::Zeus found an existing .zeus.sock'

          # if it's active, use it
          if can_connect_to_socket?
            @reusing_socket = true
            @zeus_pid = read_pid
            Compat::UI.info 'Guard::Zeus is re-using an existing .zeus.sock'
            return
          end

          # just delete it
          delete_sockfile
        end
 
        # check for an existing logfile
        if !@reusing_socket && File.exist?(zeus_logfile)
          delete_logfile 
        end

        spawn_zeus zeus_serve_command # , zeus_serve_options
        if ( boot_success = wait_for_zeus_to_be_ready )
          Compat::UI.debug 'Guard::Zeus booted successfully.'
        else
          remaining_processes = zeus_processes - zeus_ready_processes
          Compat::UI.warning "Timed out waiting for Guard::Zeus to boot (#{remaining_processes.inspect})."
        end
        boot_success
      end

      def run(paths)
        run_command zeus_push_command(paths), zeus_push_options
      end

      def run_all
        return unless options[:run_all]
        if rspec?
          run(['spec'])
        elsif test_unit?
          run(Dir['test/**/*_test.rb'] + Dir['test/**/test_*.rb'])
        end
      end

      private

      def bundler?
        @bundler ||= options[:bundler] != false && File.exist?("#{Dir.pwd}/Gemfile")
      end

      # Return a truthy socket, or catch the thrown exception
      # and return false
      def can_connect_to_socket?
        UNIXSocket.open(sockfile)
      rescue Errno::ECONNREFUSED
        false
      end

      def delete_sockfile
        Compat::UI.info 'Guard::Zeus is deleting an unusable .zeus.sock'
        File.delete(sockfile)
      end

      def delete_logfile
        Compat::UI.debug 'Guard::Zeus is deleting an existing logfile'
        File.delete(zeus_logfile)
      end

      def delete_pidfile
        Compat::UI.debug 'Guard::Zeus is deleting an existing pidfile'
        File.delete(pid_file)
      end

      def rspec?
        @rspec ||= options[:rspec] != false && File.exist?("#{Dir.pwd}/spec")
      end

      def run_command(cmd, options = '')
        system "#{cmd} #{options}"
      end

      def sockfile
        File.join(Dir.pwd, '.zeus.sock')
      end

      def spawn_zeus(cmd, options = '')
        Compat::UI.debug "About to spawn zeus"
        @zeus_pid = fork { exec "#{cmd} #{options}" }
        File.open(pid_file, 'w') { |f| f.write(@zeus_pid) }
        Compat::UI.debug "Zeus has PID #{@zeus_pid}"
      end

      def stop_zeus(force=false)
        Compat::UI.debug 'Stopping Zeus'
        return unless @zeus_pid

        if !force && options[:exit_last]
          if @stop_scheduled
            Compat::UI.debug 'Zeus already scheduled for stop!'
            return
          end
          Compat::UI.debug 'Scheduling Zeus to be stopped last'
          # Compat::UI.debug "All Zeus guards: #{zeus_guards.inspect}"
          # Compat::UI.debug "Running Zeus guards: #{running_zeus_guards.inspect}"
          fork {
            # zeus_guards.each{|g| g.stop }
            wait_for_all_guards_to_stop
            Compat::UI.debug 'Guard::Zeus proceeding to stop Zeus'
            stop_zeus(true) }
          @stop_scheduled = true
          return
        end

        Compat::UI.debug 'Stopping Zeus using a PID'

        Compat::UI.debug "Killing process #{@zeus_pid}"
        Process.kill(:INT, @zeus_pid)
        Compat::UI.debug "Killed process #{@zeus_pid}"

        begin
          Compat::UI.debug "Set process #{@zeus_pid} to wait"
          unless Process.waitpid(@zeus_pid, Process::WNOHANG)
            Compat::UI.debug "Killing process #{@zeus_pid} after wait"
            Process.kill(:KILL, @zeus_pid)
            Compat::UI.info "Killed process #{@zeus_pid} after wait"
          end
        rescue Errno::ECHILD
          Compat::UI.debug "ECHILD path"
        end

        delete_pidfile if File.exist? pid_file
        delete_logfile if File.exist? zeus_logfile
        delete_sockfile if File.exist? sockfile

        Compat::UI.info 'Zeus Stopped', reset: true
      end

      def test_unit?
        @test_unit ||= options[:test_unit] != false && File.exist?("#{Dir.pwd}/test/test_helper.rb")
      end

      def zeus_push_command(paths)
        cmd_parts = []
        cmd_parts << 'bundle exec' if bundler?
        cmd_parts << 'zeus test'
        cmd_parts << paths.join(' ')
        cmd_parts.join(' ')
      end

      def zeus_push_options
        ''
      end

      def zeus_serve_command
        cmd_parts = []
        cmd_parts << 'bundle exec' if bundler?
        cmd_parts << 'zeus' << zeus_serve_options << 'start'
        cmd_parts.join(' ')
      end

      def zeus_serve_options
        opt_parts = []
        opt_parts << options[:cli] unless options[:cli].nil?
        if ( log_parts = opt_parts.select{|part| part =~ /--log/ } ).any?
          @zeus_logfile = log_parts[-1].gsub(/--log /, '').strip
        else
          opt_parts << "--log #{zeus_logfile}"
        end
        opt_parts.join(' ')
      end

      def zeus_logfile
        @zeus_logfile ||= options[:log_file] || File.join(Dir.pwd, 'log', 'zeus_output.log')
      end

      def search_zeus_logfile(pattern_str)
        return [] unless File.exist? zeus_logfile
        cmd = "awk '/#{pattern_str}/{print $0}' #{zeus_logfile}"
        cmd << " | awk '{print $4}' | cut -d '/' -f 1"
        # Compat::UI.debug "Zeus log search command: #{cmd}"
        `#{cmd}`.lines.map(&:strip).delete_if(&:empty?)
      end

      def collect_zeus_processes_from_plan_hash(plan_hash)
        processes = []
        plan_hash.each do |k, v|
          if v.is_a?(Hash)
            processes << k
            processes.concat collect_zeus_processes_from_plan_hash(v)
          end
        end
        processes
      end
      def zeus_processes
        @zeus_processes ||= collect_zeus_processes_from_plan_hash(zeus_plan)
      end
      def zeus_ready_processes
        search_zeus_logfile('SReady')
      end

      def zeus_booted?
        zeus_ready_processes.any?
      end
      def zeus_ready?
        return true if @zeus_ready
        return false unless zeus_booted?
        return false if ( zeus_processes - zeus_ready_processes ).any?
        @zeus_ready = true
      end

      def sleep_time; options[:timeout].to_f / MAX_WAIT_COUNT.to_f end
      def wait_for_loop
        count = 0
        while !yield && count < MAX_WAIT_COUNT
          wait_for_action
          count += 1
        end
        !(count == MAX_WAIT_COUNT)
      end
      def wait_for_action; sleep sleep_time end
      def wait_for_zeus_to_be_ready; wait_for_loop { zeus_ready? } end
      def wait_for_all_guards_to_stop
        status = wait_for_loop {
          Compat::UI.debug "Running guards: #{rg = running_zeus_guards}"
          rg.empty? }
        if status then Compat::UI.debug 'All Zeus guards stopped successfully'
        else
          Compat::UI.warning "Timed out waiting for Zeus guards to stop: #{running_zeus_guards.map(&:name)}"
        end
        status
      end
      def zeus_guards
        Guard.state.session.plugins.all.select do |p|
          plugin_options = p.options if p.respond_to?(:options) && p.options.any?
          plugin_options ||= p.runner.options if p.respond_to?(:runner) && p.runner.respond_to?(:options)
          plugin_options[:zeus]
        end
      end
      def running_zeus_guards
        zeus_guards.select{|p| zeus_guard_running? p }
      end
      def zeus_guard_running?(p)
        Compat::UI.debug "Checking if #{p.name} is still running..."
        return p.running? if p.respond_to? :running?
        pr = p.runner if p.respond_to? :runner
        return pr.running? if pr && pr.respond_to?(:running?)
        p_pid   = p.pid  if p.respond_to? :pid
        p_pid ||= pr.pid if pr && pr.respond_to?(:pid)
        p_pid ||= read_pid( p.options[:pid_file]) if p.respond_to?(:options) && p.options[:pid_file]
        p_pid ||= read_pid(pr.options[:pid_file]) if pr && pr.respond_to?(:options) && pr.options[:pid_file]
        return true if p_pid && `ps -p #{p_pid} | wc -l`.strip.to_i == 2
        false
      end

      def read_pid(path_to_pid_file=nil)
        Integer( File.read( path_to_pid_file ||= pid_file ) )
      rescue ArgumentError; nil end

      def pid_file
        @pid_file ||= File.expand_path( options[:pid_file] || File.join(
          Dir.pwd, 'tmp', 'pids', 'zeus_wrapper.pid' ) )
      end

      def zeus_json_path
        return @zeus_json_path if @zeus_json_path
        app_json_path = File.join Dir.pwd, 'zeus.json'
        return @zeus_json_path = app_json_path if File.exist? app_json_path
        zeus_path = `which zeus`.strip
        gems_dir = File.join zeus_path, '..', '..', 'gems'
        zeus_gem_dir = File.join gems_dir, "zeus-#{Zeus::VERSION}"
        default_json_path = File.join zeus_gem_dir, 'examples', 'zeus.json'
        return unless File.exist? default_json_path
        @zeus_json_path = default_json_path
      end
      def zeus_json; @zeus_json ||= JSON.parse File.read(zeus_json_path) end
      def zeus_plan; zeus_json['plan'] end

    end
  end
end
