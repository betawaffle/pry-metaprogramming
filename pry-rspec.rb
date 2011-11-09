# require 'coverage'

# module Coverage
#   class << self
#     def result_with_baseline
#       r = result_without_baseline

#       return r unless @baseline
#       res = {}

#       base = @baseline
#       base.each_pair do |src, cov|
#         orig = r[src] || []
#         line = []
#         cov.each_with_index do |c, i|
#           case c
#           when nil, 1
#             line[i] = nil
#           else
#             line[i] = orig[i] || 0
#           end
#         end

#         res[src] = line.freeze
#       end

#       r.each_pair do |src, cov|
#         next if res.has_key? src

#         res[src] = cov.reduce([]) { |l, c| l << c; l }.freeze
#       end

#       res.freeze
#     end

#     alias_method :result_without_baseline, :result
#     alias_method :result, :result_with_baseline

#     def baseline
#       r, w = IO.pipe

#       pid = fork
#       unless pid
#         $stdin.reopen('/dev/null', 'r')

#         $stdout.reopen('/dev/null', 'a')
#         $stderr.reopen('/dev/null', 'a')
#       end

#       yield

#       unless pid
#         base = result_without_baseline
#         Marshal.dump(base, w)
#         exit!
#       end

#       # puts 'Loading...'
#       @baseline = Marshal.load(r)
#       # puts 'Waiting...'
#       Process.wait(pid)
#     end
#   end
# end

RSpecCommands = Pry::CommandSet.new do
  command 'rspec', 'Run specs.' do |*args|
    unless defined? RSpec
      run 'load-rspec'
    end

    RSpec::Core::Runner.run(args, output, output)
  end

  command 'load-rspec', 'Load RSpec.' do |*args|
    args.compact!
    opts = Slop.parse!(args) do |opt|
      opt.on :'without-helper', "Don't load spec_helper.rb."
    end

    require 'rspec'

    unless opts[:'without-helper']
      if File.exists? File.join(Dir.getwd, 'config', 'environment.rb')
        hook_into_rails(false) unless defined? Rails
        hook_into_rails_env('test')
      end

      # Coverage.baseline { require 'spec_helper' }
      require 'spec_helper'
    end
  end

  helpers do
    def hook_into_rails(logger = nil)
      kernel_orig = Kernel.method(:require)
      kernel_orig.append do |f|
        next unless f == 'rails'
        kernel_orig.redefine

        rails_loaded(logger)
      end
    end

    def hook_into_rails_env(default = 'development')
      env_file = File.join(Dir.getwd, 'config', 'environment')

      object_orig = Object.method(:require)
      object_orig.alter do |args|
        next unless args[0].match %r{^#{env_file}(?:\.rb)?$}
        object_orig.redefine

        ENV['RAILS_ENV'] ||= default_env

        output.puts "Loading Rails Environment... \e[0;37;42m  #{ENV['RAILS_ENV'].upcase}  \e[0m"
      end
    end

    def rails_loaded(logger = nil)
      output.puts "  Rails #{Rails.version} Loaded"

      orig = Rails::Application.method(:inherited)
      orig.append { |app| rails_app_created(app) }

      if logger
        Rails.logger = logger == true ? Logger.new(output) : logger
      end
    end

    def rails_app_created(app)
      output.puts "  Rails Application Created"
    end
  end
end
