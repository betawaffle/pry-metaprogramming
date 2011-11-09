# require 'fiber'
require 'ruby-debug'

include Debugger

=begin
class Tracer
  class << self
    private :new

    def create(&block)
      @inst ||= new(&block)
    end
  end

  attr_reader :error

  def initialize(*args, &block)
    @fiber = Fiber.new do
      begin
        event, scope, location, method, klass = Fiber.yield
        block.call(event, scope, location, method, klass)
      rescue
        binding.pry
        error = $!
        break
      end while true
      binding.pry
      error
    end

    untrace_var :$trace, nil

    @fiber.resume(*args)
    @trace = $trace = false

    trace_var :$trace, lambda { |v| set_trace_func(v ? method(:trace).to_proc : nil) unless v == @trace; @trace = v }
  end

  def trace(event, file, line, id, scope, klass)
    return if klass.to_s.match %r{^Pry}
    unless @fiber and @fiber.alive?
      binding.pry
      $trace = false
      return
    end

    @error = @fiber.resume(event, scope, [file, line], id, klass)
    # $trace = false if @error
  end
end

Pry.commands.command('trace-init', "Trace execution") do
  Tracer.create do |event, scope, location, method, klass|
    if $step == true or $step == event
      $trace = false
      scope.eval("_ev_ = '#{event}'")
      scope.pry
    end
  end
end

Pry.commands.command('trace', "Trace execution") do
  $trace = true
  $step = true
end
=end

Pry.commands.command('step', "Step though execution") do |event|
  # $trace ||= true
  $step = event ? event : true

  run 'exit'
end

=begin
def tracer
  block = Proc.new # This will raise an exception for us!
  Tracer.new do
    begin
      event, scope, location, method, klass = Fiber.yield
      block.call(event, scope, location, method, klass)
    rescue StopTrace
      return
    rescue
      return $!
    end while true
  end
end
=end

class BasicObject
  def send_and_pry(symbol, *args)
    $step = true

    called = 0
    tracer = lambda do |event, file, line, id, scope, klass|
      if id == symbol
        called += 1 if event == 'call'
        called -= 1 if event == 'return'
      end

      return unless called > 0
      return unless $step == true or $step == event

      $step = nil
      scope.eval("_ev_ = '#{event}'")
      scope.pry
    end
    set_trace_func tracer
    begin
      ret = __send__ symbol, *args
    ensure
      set_trace_func nil
    end
    ret
  end
end

class Binding
  def fake(file, line)
    orig = method(:eval)
    define_singleton_method(:eval) do |s, f = nil, l = nil|
      orig.call(s, f || file.to_s, l || line.to_i)
    end

    self
  end

  def fake_class(name)
    orig = method(:eval)
    define_singleton_method(:eval) do |s, f = nil, l = nil|
      case s
      when 'self.class'
        name.to_s
      else
        orig.call(s, f, l)
      end
    end

    self
  end

  def fake_method(name)
    orig = method(:eval)
    define_singleton_method(:eval) do |s, f = nil, l = nil|
      case s
      when '__method__'
        name.to_s
      else
        orig.call(s, f, l)
      end
    end

    self
  end
end

# This may not really be needed...
Pry.commands.command('show-ex', "Show the context for the last exception") do |num|
  if ex = target.eval('_ex_')
    file, line, _ = ex.backtrace.first.split(':', 3)
    fake = Pry.binding_for(ex).fake(file, line)

    Pry.run_command("whereami #{num}", :context => fake)
  end
end

# Pry.config.exception_handler = proc do |out, ex, _pry_|
#   # out.puts "#{ex.class}: #{ex.message}"
#   # out.puts "from #{ex.backtrace.first}"
#   # _pry_.run_command 'cat --ex'
# end

# Pry.commands.command('step', "Step though execution") do |event|
#   $step = event ? event : true

#   run 'exit'
# end
