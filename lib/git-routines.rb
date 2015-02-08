require 'git-routines/version'
require 'hooks'
require 'fileutils'

PLUGINS = {
  'show-summary' => 'Show story summary after starting',
  'pivotal' => 'PivotalTracker integration',
  'rebase' => 'Rebase to default branch before finishing',
  'pull-request' => 'Open pull request after finishing',
}

class GitRoutines
  include Hooks
  include Hooks::InstanceHooks

  define_hook :setup
  define_hook :before_start
  define_hook :after_start
  define_hook :before_finish
  define_hook :after_finish

  class << self
    attr_accessor :default_branch
    attr_accessor :title
    attr_accessor :summary

    def start
      run_hook :setup
      run_hook :before_start
      git :checkout, "-b #{branch}"
      run_hook :after_start
    end

    def finish
      @branch = current_branch
      run_hook :setup
      run_hook :before_finish
      git :checkout, default_branch
      run_hook :after_finish
    end

    def branch
      @branch ||= ask_for('Branch name')
      @branch.strip.downcase.gsub(/[^\w\d\/]+/, '-')
    end

    def default_branch
      @default_branch ||= config(
        'git-start.default-branch',
        'Default branch name',
        :local,
        'master'
      )
    end

    def ask_for(question, default = nil)
      print "#{question}#{" [#{default}]" unless default.nil?}: "
      value = STDIN.readline.strip
      value == '' ? default : value
    end

    def select_multiple_of(question, *option_lists)
      select_of("#{question} (comma separated)", *option_lists)
    end

    def select_one_of(question, *option_lists)
      select_of(question, *option_lists).first
    end

    def git(command, *options)
      `git #{command} #{options.map{ |o| o.is_a?(Symbol) ? "--#{o}" : o}.join(' ')}`
    end

    def config(key, question = nil, scope = nil, default = nil)
      value = git(:config, key).strip
      if value == '' and !question.nil?
        value = ask_for(question, default)
        git :config, scope, key, %{"#{value}"}
      end
      value
    end

    def requires_gem(name)
      require name
    rescue LoadError
      abort "\nPlease install the `#{name}` Gem first:\n\ngem install #{name}\n\n"
    end

    def include_plugin(plugin)
      @included_plugins ||= []
      return if @included_plugins.include?(plugin)
      @included_plugins << plugin
      file = File.expand_path("../git-routines/plugins/#{plugin}.rb", __FILE__)
      instance_eval File.read(file)
    end

    def current_branch
      `git rev-parse --abbrev-ref HEAD`.strip
    end

    private

    def select_of(question, *option_lists)
      list_options *option_lists
      choice = ask_for(question)
      abort 'Command aborted.' if choice.nil?
      choice.split(',').map do |item|
        item =~ /^\d+$/ ? item.to_i - 1 : item.to_sym
      end
    end

    def list_options(*option_lists)
      option_lists.each do |list|
        next unless list.any?
        puts "\n"
        list.each_with_index do |a, b|
          key, value = list.is_a?(Hash) ? [a[0], a[1]] : [b + 1, a]
          puts "[#{key}]".to_s.rjust(@column_size) + " #{value}"
        end
      end
      puts "\n"
    end
  end

  setup do
    @column_size = 5
    plugins = config('git-routines.plugins').strip.split(',')
    if plugins.empty?
      question = 'Choose plugins (comma separated)'
      select_multiple_of(question, PLUGINS.values).each do |index|
        plugins << PLUGINS.keys[index]
      end
      git :config, :local, 'git-routines.plugins', plugins.join(',')
    end
    plugins.each do |plugin|
      include_plugin plugin
    end
  end
end
