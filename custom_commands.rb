module CustomCommands
  # Dir[File.join(File.expand_path('../custom_commands', __FILE__), '*.rb')].each do |f|
  #   const = File.basename(f)[/^.+(?=\.rb$)/].gsub(/(?:^|_)(.)/) { $1.upcase }
  #   p const, f
  #   autoload const, f
  # end

  Benchmarking = Pry::CommandSet.new do
    command 'time', 'Benchmark a command.' do
      ret  = nil
      time = Benchmark.realtime do
        ret = _pry_.process_line arg_string, '', target
      end

      output.puts time

      ret
    end

    command 'measure', 'Measure the time it takes to execute an expression.', :keep_retval => true do |label|
      ret = nil

      expr = _pry_.r(target)
      time = measure(label) { ret = target.eval(expr) }

      _pry_.inject_local '_time_', time, target
      output.puts time
      ret
    end

    command 'benchmark', 'Measure the time it takes to execute expressions.', :keep_retval => true do |label|
      if $benchmarking
        throw :execute
      end

      width = 0
      exprs = []
      extra = []

      _pry_.push_prompt [
        proc { 'benchmark > ' },
        proc { '          * ' }
      ]

      catch :execute do
        $benchmarking = true
        begin
          report = catch(:label) do
            code = _pry_.r(target)
            code = Pry::Indent.new.indent(code)
            expr = { :code => code, :label => nil }
            expr[:proc] = lambda { expr[:ret] = target.eval(code) }
            exprs << expr

            render_output true, 1, colorize_code(code)

            nil
          end

          if report and exprs.last
            # label = label[/^.+?(?=\:?\s*$)/]
            width = report.size if report.size > width
            exprs.last[:label] = report
          end
        ensure
          _pry_.pop_prompt
        end while true
      end

      execute(label, width, exprs, extra).tap { $benchmarking = false }
      exprs.map { |e| e[:ret] }
    end

    command 'report-as', 'Set label for previous expression.' do
      throw :label, arg_string
    end

    helpers do
      require 'benchmark'
      include Benchmark

      def execute(label, width, exprs, extra)
        stdout = STDOUT.dup
        STDOUT.reopen(output)

        benchmark("%#{width}s #{CAPTION}" % label, width + 2, FMTSTR, *extra.map { |x| "%#{width}s" % x[:label] }) do |b|
          exprs.map { |e| e[:time] = b.report(e[:label], &e[:proc]) }.tap do |times|
            extra.map { |e| e[:proc].call(*times) }
          end
        end
      ensure
        STDOUT.reopen(stdout)
      end
    end
  end

  Enumeration = Pry::CommandSet.new do
    command 'each', 'Start enumerating.' do
      enum = target_self.is_a?(Enumerator) ? target_self : target_self.each
      enum.each do |o|

      end
      next_binding(enum)
    end

    command 'next', 'Move to the next object in the enumerator.' do
      _pry_.binding_stack.pop unless target_self.is_a? Enumerator
      next_binding
    end

    command 'rewind', 'Rewind the enumeration sequence.' do
      _pry_.binding_stack.pop unless target_self.is_a? Enumerator
      next_binding(enum_rewind)
    end

    helpers do
      def enum_rewind
        enum = _pry_.binding_stack.last.eval('self')
        enum.rewind
      end

      def next_binding(enum = nil)
        enum = _pry_.binding_stack.last.eval('self') unless enum

        begin
          _pry_.binding_stack.push Pry.binding_for(enum.next)
        rescue StopIteration
          throw :breakout
        end
      end
    end
  end

  Fibers = Pry::CommandSet.new do
  command 'fiber-start', 'Start a new fiber.', :keep_retval => true do |name|
    fiber, args = fiber_init(name), target

    if Fiber.root?
      while fiber.is_a? Fiber and fiber.alive?
        from, to, args = r = fiber.transfer(*args)

        if from == fiber
          fiber = to
          next
        end
      end

      other, args = other.transfer(*args) while other.is_a? Fiber and other.alive?
    else
      Fiber[0].transfer(Fiber.current, other, *args)
    end
  end

  command %r{fiber-(\d+)}, 'Resume an inactive fiber.', :keep_retval => true do |index|
    if index.match %r{^\d+$}
      fiber = Fiber[index.to_i]
    else
      fiber = Fiber.each { |f| break f if f.name == index }
    end

    unless fiber
      output.puts "Fiber does not exist."
      next
    end

    fiber.transfer *target.eval("[#{arg_string}]")
  end

  command 'fibers', 'List inactive fibers.', :keep_retval => true do
    output.puts
    output.puts "\e[1mFibers:\e[0m"
    Fiber.each do |f|
      output.puts "%6d: %s%s" % [f.index, f.name, f.current? ? ' (current)' : nil]
    end
  end

  command 'yield', 'Yield to the calling fiber.', :keep_retval => true do
    args = target.eval("[#{arg_string}]")

    begin
      next fiber_yield(*args)
    rescue FiberError
    end
  end

  helpers do
    def fiber_init(name = nil)
      f = Pry.method(:start).to_fiber(Fiber)
      f.name = name if name
      f
    end

    def fiber_yield(*args)
      Fiber.yield(*args)
    end
  end
end

  ObjectSpace = Pry::CommandSet.new do
    command 'gc', 'Run the garbage collector.', :keep_retval => false do
      garbage_collect
    end

    command 'count-objects', 'Count all objects.', :keep_retval => true do
      count_objects
    end

    command 'each-object', 'Iterate over each object.', :keep_retval => false do |mod|
      mod = Kernel.const_get(mod) rescue nil

      unless mod.is_a? Module
        output.puts 'Expected a class or module name.'
        next
      end

      Pry.start each_object(mod)
    end

    helpers do
      include ::ObjectSpace
    end
  end
end
