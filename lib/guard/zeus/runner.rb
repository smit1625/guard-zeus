# Needed for socket_file
require 'socket'
require 'tempfile'
require 'digest/md5'

require 'guard/compat/plugin'

module Guard
  class Zeus < Plugin
    class Runner
      attr_reader :options

      def initialize(options = {})
        @zeus_pid = nil
        @options = { run_all: true }.merge(options)
        Compat::UI.info 'Guard::Zeus Initialized'
      end

      def kill_zeus
        stop_zeus
      end

      def launch_zeus(action)
        Compat::UI.info "#{action}ing Zeus", reset: true

        # check for a current .zeus.sock
        if File.exist? sockfile
          Compat::UI.info 'Guard::Zeus found an existing .zeus.sock'

          # if it's active, use it
          if can_connect_to_socket?
            Compat::UI.info 'Guard::Zeus is re-using an existing .zeus.sock'
            return
          end

          # just delete it
          delete_sockfile
        end

        spawn_zeus zeus_serve_command, zeus_serve_options
      end

      def run(paths)
        run_command zeus_push_command(paths), zeus_push_options
      end

      def run_all
        return unless options[:run_all]
        if rspec?
          run(['rspec'])
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
        @zeus_pid = fork do
          exec "#{cmd} #{options}"
        end
      end

      def stop_zeus
        return unless @zeus_pid

        Process.kill(:INT, @zeus_pid)

        begin
          unless Process.waitpid(@zeus_pid, Process::WNOHANG)
            Process.kill(:KILL, @zeus_pid)
          end
        rescue Errno::ECHILD
        end

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
        cmd_parts << 'zeus start'
        cmd_parts.join(' ')
      end

      def zeus_serve_options
        opt_parts = []
        opt_parts << options[:cli] unless options[:cli].nil?
        opt_parts.join(' ')
      end
    end
  end
end
