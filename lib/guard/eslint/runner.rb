# coding: utf-8

require 'json'
require 'open3'

module Guard
  class Eslint
    # This class runs `eslint` command, retrieves result and notifies.
    # An instance of this class is intended to invoke `eslint` only once in its lifetime.
    class Runner
      def initialize(options)
        @options = options
      end

      attr_reader :options

      def run(paths)
        paths = options[:default_paths] unless paths

        passed = run_for_check(paths)
        case options[:notification]
        when :failed
          notify(passed) unless passed
        when true
          notify(passed)
        end

        run_for_output(paths)

        passed
      end

      def failed_paths
        result.reject { |f| f[:messages].empty? }.map { |f| f[:filePath] }
      end

      private

      attr_accessor :check_stdout, :check_stderr

      def run_for_check(paths)
        command = command_for_check(paths)
        (stdout, stderr, status) = Open3.capture3(*command)
        self.check_stdout = stdout
        self.check_stderr = stderr
        status
      rescue SystemCallError => e
        fail "The eslint command failed with #{e.message}: `#{command}`"
      end

      ##
      # Once eslint reports a failure, we have to run it again to show the results using the
      # formatter that it uses for output.
      # This because eslint doesn't support multiple formatters during the same run.
      def run_for_output(paths)
        command = [options[:command]]

        command.concat(args_specified_by_user)
        command.concat(['-f', options[:formatter]]) if options[:formatter]
        command.concat(paths)
        system(*command)
      end

      def command_for_check(paths)
        command = [options[:command]]

        command.concat(args_specified_by_user)
        command.concat(['-f', 'json', '-o', json_file_path])
        command.concat(paths)
      end

      def args_specified_by_user
        @args_specified_by_user ||= begin
          args = options[:cli]
          case args
          when Array    then args
          when String   then args.shellsplit
          when NilClass then []
          else fail ':cli option must be either an array or string'
          end
        end
      end

      def json_file_path
        @json_file_path ||= begin
          json_file.close
          json_file.path
        end
      end

      ##
      # Keep the Tempfile instance around so it isn't garbage-collected and therefore deleted.
      def json_file
        @json_file ||= begin
          # Just generate random tempfile path.
          basename = self.class.name.downcase.gsub('::', '_')
          Tempfile.new(basename)
        end
      end

      def result
        @result ||= begin
          File.open(json_file_path) do |file|
            # Rubinius 2.0.0.rc1 does not support `JSON.load` with 3 args.
            JSON.parse(file.read, symbolize_names: true)
          end
        end
      rescue JSON::ParserError
        fail "eslint JSON output could not be parsed. Output from eslint was:\n#{check_stderr}\n#{check_stdout}"
      end

      def notify(passed)
        image = passed ? :success : :failed
        Notifier.notify(summary_text, title: 'ESLint results', image: image)
      end

      # rubocop:disable Metric/AbcSize
      def summary_text
        summary = {
          files_inspected: result.count,
          errors: result.map { |x| x[:errorCount] }.reduce(:+),
          warnings: result.map { |x| x[:warningCount] }.reduce(:+)
        }

        text = pluralize(summary[:files_inspected], 'file')
        text << ' inspected, '

        errors_count = summary[:errors]
        text << pluralize(errors_count, 'error', no_for_zero: true)
        text << ' detected, '

        warning_count = summary[:warnings]
        text << pluralize(warning_count, 'warning', no_for_zero: true)
        text << ' detected'
      end
      # rubocop:enable Metric/AbcSize

      def pluralize(number, thing, options = {})
        text = ''

        if number == 0 && options[:no_for_zero]
          text = 'no'
        else
          text << number.to_s
        end

        text << " #{thing}"
        text << 's' unless number == 1

        text
      end
    end
  end
end
