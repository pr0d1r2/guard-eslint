require 'guard/compat/plugin'

module Guard
  class Eslint < Plugin
    autoload :Runner, 'guard/eslint/runner'

    # Initializes a Guard plugin.
    # Don't do any work here, especially as Guard plugins get initialized
    #   even if they are not in an active group!
    #
    # @param [Hash] options the custom Guard plugin options
    # @option options [Array<Guard::Watcher>] watchers the Guard plugin file watchers
    # @option options [Symbol] group the group this Guard plugin belongs to
    # @option options [Boolean] any_return allow any object to be returned from a watcher
    #
    def initialize(options = {})
      super

      @options = {
        all_on_start: false,
        keep_failed: false,
        notification: :failed,
        cli: nil,
        formatter: nil,
        command: 'eslint',
        default_paths: ['**/*.js', '**/*.es6'],
      }.merge(options)

      @failed_paths = []
    end

    # Called once when Guard starts. Please override initialize method to init stuff.
    #
    # @raise [:task_has_failed] when start has failed
    # @return [Object] the task result
    #
    def start
      Compat::UI.info 'Guard::ESLint is running'
      run_all if options[:all_on_start]
    end

    # Called when `reload|r|z + enter` is pressed.
    # This method should be mainly used for "reload" (really!) actions like reloading
    #   passenger/spork/bundler/...
    #
    # @raise [:task_has_failed] when reload has failed
    # @return [Object] the task result
    #
    def reload
      runner.reload
    end

    # Called when just `enter` is pressed
    # This method should be principally used for long action like running all specs/tests/...
    #
    # @raise [:task_has_failed] when run_all has failed
    # @return [Object] the task result
    #
    def run_all
      Compat::UI.info 'Inspecting all Javascript files'
      inspect_with_eslint
    end

    # Called on file(s) additions that the Guard plugin watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_additions has failed
    # @return [Object] the task result
    #
    def run_on_additions(paths)
      run_partially(paths)
    end

    # Called on file(s) modifications that the Guard plugin watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_modifications has failed
    # @return [Object] the task result
    #
    def run_on_modifications(paths)
      run_partially(paths)
    end

    private

    def inspect_with_eslint(paths = [])
      runner = Runner.new(@options)
      passed = runner.run(paths)
      @failed_paths = runner.failed_paths
      throw :task_has_failed unless passed
    rescue => error
      Compat::UI.error 'The following exception occurred while running guard-eslint: ' \
                       "#{error.backtrace.first} #{error.message} (#{error.class.name})"
    end

    def run_partially(paths)
      paths += @failed_paths if @options[:keep_failed]
      paths = clean_paths(paths)

      return if paths.empty?

      displayed_paths = paths.map { |path| smart_path(path) }
      Compat::UI.info "Inspecting JS code style: #{displayed_paths.join(' ')}"

      inspect_with_eslint(paths)
    end

    def clean_paths(paths)
      paths = paths.dup
      paths.map! { |path| File.expand_path(path) }
      paths.uniq!
      paths.reject! do |path|
        next true unless File.exist?(path)
        included_in_other_path?(path, paths)
      end
      paths
    end

    def included_in_other_path?(target_path, other_paths)
      dir_paths = other_paths.select { |path| File.directory?(path) }
      dir_paths.delete(target_path)
      dir_paths.any? do |dir_path|
        target_path.start_with?(dir_path)
      end
    end

    def smart_path(path)
      if path.start_with?(Dir.pwd)
        Pathname.new(path).relative_path_from(Pathname.getwd).to_s
      else
        path
      end
    end
  end
end
