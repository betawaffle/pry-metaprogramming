require 'fiber'

class Fiber
  @fibers = [Fiber.current.__id__] # Hope that we weren't required inside of another fiber...

  class << self
    def [](index)
      begin
        find_by_object_id(@fibers[index])
      rescue RangeError
        nil
      end
    end

    def compact!
      @fibers = @fibers.reduce([]) do |alive, id|
        begin
          fiber = find_by_object_id(id)
        rescue RangeError
        end

        next alive unless fiber

        alive << fiber.tap { |f| f.instance_variable_set :@index, alive.size }.__id__
      end
    end

    def each
      return to_enum unless block_given?

      @fibers.reduce(0) do |count, id|
        begin
          if fiber = find_by_object_id(id)
            yield fiber
          else
            next count
          end
        rescue RangeError
          next count
        end

        count += 1
      end
    end

    def new_with_index(&block)
      unless @index
        # current.instance_variable_set :@name, 'root'
        current.instance_variable_set :@index, 0

        @index = 0
      end

      new_without_index(&block).tap do |f|
        f.instance_variable_set :@index, next_index

        @fibers[f.index] = f.__id__
      end
    end

    alias_method :new_without_index, :new
    alias_method :new, :new_with_index

    def root?
      defined?(@index) ? current.index == 0 : true
    end

    private

    def find_by_object_id(id)
      ObjectSpace._id2ref(id).tap { |f| return nil unless f.is_a? Fiber and f.alive? } if id
    end

    def next_index
      @index = @fibers.size
    end
  end

  def [](key)
    @data[key]
  end

  def []=(key, value)
    @data[key] = value
  end

  def current?
    Fiber.current == self
  end

  def index
    @index || __id__
  end

  def name
    @name || begin
      if @index
        "fiber-#{@index}"
      else
        @index = 0
        @name = 'root'
      end
    end
  end

  def name=(name)
    @name = name
  end

  def root?
    index == 0
  end
end
