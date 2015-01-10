require 'git-start/version'

class GitStart
  attr_accessor :branch
  attr_accessor :default_branch

  class << self
    def start
      git :checkout, "-b #{branch}"
    end

    def finish
      git :checkout, default_branch
    end

    protected

    def branch
      @branch ||= ask_for('Branch name')
    end

    def default_branch
      @branch ||= ask_for('Default branch name', 'master')
    end

    def ask_for(question, default = nil)
      print "#{question}#{" [#{default}]" unless default.nil?}: "
      value = STDIN.readline.strip
      value == '' ? default : value
    end

    def git(command, *options)
      puts "git #{command} #{options.map{ |o| o.is_a?(Symbol) ? "--#{o}" : o}.join(' ')}"
      `git #{command} #{options.map{ |o| o.is_a?(Symbol) ? "--#{o}" : o}.join(' ')}`
    end
  end
end
