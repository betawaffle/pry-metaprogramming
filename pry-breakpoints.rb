=begin
class Tracer
  class << self
    def trace
      tracer = Fiber.new
      tracer.start
      begin
        yield
      ensure
        tracer.stop
      end
    end
  end

  def initialize
    @fiber = Fiber.new do
      event, file, line, id, context, classname
    end
    @last = {}
  end

  def trace(event, file, line, id, context, classname)
    puts "\n#{file}" unless file == @last[:file]
    info = %(%8s \e[0;34m%-30s\e[0m\t\e[0;33m%s\e[0m) % [event, id, classname]
    context.eval('local_variables').each do |name|
      info << %(\n                  #{name} = ) << binding.eval(name.to_s).inspect
    end

    unless line == @last[:line]
      printf %(       %s\n), info
    else
      printf %(%5d: %s\n), line.to_i, info
    end

    @last = { :file => file, :line => line }
  end

  def start
    set_trace_func lambda { |*args| @fiber.resume(*args) }
  end

  def stop
    set_trace_func nil
  end
end

def trace(tracer)
  tracer ||= begin
    def trace(event, file, line, id, binding, classname)
      hooks = @hooks[event]

      method_hooks = hooks[id]
      fileln_hooks = hooks["#{File.basename(file)}:#{line}"]

      unless method_hooks.nil? or method_hooks.empty?
        method_hooks.each { |hook| hook.call(event, file, line, id, binding, classname) }
      end

      unless fileln_hooks.nil? or fileln_hooks.empty?
        fileln_hooks.each { |hook| hook.call(event, file, line, id, binding, classname) }
      end

      puts "\n#{file}" unless file == @last[:file]

      info = %(%8s \e[0;34m%-30s\e[0m\t\e[0;33m%s\e[0m) % [event, id, classname]
      binding.eval('local_variables').each do |name|
        info << %(\n                  #{name} = ) << binding.eval(name.to_s).inspect
      end

      unless line == @last[:line]
        printf %(       %s\n), info
      else
        printf %(%5d: %s\n), line.to_i, info
      end

      @last = { :file => file, :line => line }
    end
  end
  set_trace_func tracer
  yield
ensure
  set_trace_func nil
end
=end

=begin
class Breakpoint
  @breakpoints = {}

  class << self
    def [](key)
      @breakpoints[key]
    end

    def []=(key, val)
      @breakpoints[key] = val
    end

    def disable
      set_trace_func nil
    end

    def enable
      set_trace_func method(:trace).to_proc
    end

    def watch(event)
      @watching[event] = true

      set_trace_func eval("lamda")
    end

    def trace(event, file, line, id, context, classname)
      matched()
    end
  end

  def initialize(event)
    @event
  end

  def match()

  end
end
=end

=begin
module Breakpoints
  # EVENTS = %w(c-call c-return call class end line raise return)

  @breakpoints = {}

  class << self
    def [](key)
      @breakpoints[key]
    end

    def []=(key, val)
      @breakpoints[key] = val
    end

    def disable
      set_trace_func nil
    end

    def enable
      set_trace_func method(:trace).to_proc
    end

    def set(event, file = nil, line = nil)
      path = file ? "#{File.absolute_path(file)}" : nil
      path << ":#{line}" if path and line

      key = "#{event}"
      val = block_given? ? Proc.new : true

      key << " > #{path}" if path

      self[key] = val
    end

    def trace(event, file, line, id, context, classname)
      ex = $!
      keys = [
        "#{event}",
        "#{event} > #{file}",
        "#{event} > #{file}:#{line}"
      ]

      key = keys.reverse.find do |k|
        b = @breakpoints[k]
        b.is_a?(Proc) ? b.call(event, file, line, id, context, classname) : b
      end

      return unless key

      case event
      when 'raise'
        printf "\e[1;37mBreakpoint!\e[0m raise %s, %s\n", ex.class, ex.message.inspect
      else
        printf "\e[1;37mBreakpoint!\e[0m %s\n", event
      end

      pry = Pry.new
      pry.set_last_exception($!, context) if $!
      pry.process_line('whereami', '', context)
      pry.repl(context)
    end
  end
end

Breakpoints.set('raise') # { |_, f| f.match %r[^#{Dir.pwd}] }
Breakpoints.enable
=end

=begin
class Tracer
  def initialize
    @proc = method(:trace).to_proc
    @last = {}

    @hooks = %w(c-call c-return call class end line raise return).reduce({}) do |hooks, event|
      hooks[event] = {}
    end
  end

  def trace(event, file, line, id, binding, classname)
    hooks = @hooks[event]

    method_hooks = hooks[id]
    fileln_hooks = hooks["#{File.basename(file)}:#{line}"]

    unless method_hooks.nil? or method_hooks.empty?
      method_hooks.each { |hook| hook.call(event, file, line, id, binding, classname) }
    end

    unless fileln_hooks.nil? or fileln_hooks.empty?
      fileln_hooks.each { |hook| hook.call(event, file, line, id, binding, classname) }
    end

    puts "\n#{file}" unless file == @last[:file]

    info = %(%8s \e[0;34m%-30s\e[0m\t\e[0;33m%s\e[0m) % [event, id, classname]
    binding.eval('local_variables').each do |name|
      info << %(\n                  #{name} = ) << binding.eval(name.to_s).inspect
    end

    unless line == @last[:line]
      printf %(       %s\n), info
    else
      printf %(%5d: %s\n), line.to_i, info
    end

    @last = { :file => file, :line => line }
  end

  def hook_method(event, name)
    raise ArgumentError unless @hooks.has_key? event
    raise ArgumentError unless block_given?

    @hooks[event][name] = Proc.new
  end

  def hook_file(event, file, line)
    raise ArgumentError unless @hooks.has_key? event
    raise ArgumentError unless block_given?

    @hooks[event]["#{File.basename(file)}:#{line}"] = Proc.new
  end

  def start
    set_trace_func @proc
  end

  def stop
    set_trace_func nil
  end
end
=end
