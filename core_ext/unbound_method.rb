class UnboundMethod
  alias_method :__bind, :bind
  def bind(obj)
    __bind(obj).tap do |m|
      m.instance_variable_set :@_origin, origin
    end
  end
  alias_method :bound_to, :bind

  def changed?
    receiver_class.__instance_method(name) != self
  end

  def current
    cur = receiver_class.__instance_method(name).tap { |m| return self if m == self }

    unless cur.owner == receiver_class
      cur.instance_variable_set :@_receiver_class, receiver_class
      cur.instance_variable_set :@_origin, cur.owner.__instance_method(sym)
    end

    cur
  end

  def origin
    @_origin ||= self
  end

  def receiver_class
    @_receiver_class ||= owner
  end

  def redefine_on_owner(with = nil, &block)
    __redefine_on owner, with, &block
  end

  def remove_from_owner
    __remove_from owner
  end

  alias_method :remove, :remove_from_owner

  def singleton?
    owner.singleton?
  end

  def undefine_on_owner
    __undefine_on owner
  end

  def undefine_on_receiver_class
    __undefine_on receiver_class
  end

  alias_method :undefine, :undefine_on_receiver_class

  private

  def __redefine_on(mod, with = nil)
    raise ArgumentError unless mod.is_a? Module

    if block_given?
      with = yield(with == :current ? mod.instance_method(name) : origin)
    else
      with = origin unless with
    end

    mod.send :define_method, name, with
    mod.instance_method name
  end

  def __remove_from(mod)
    raise ArgumentError unless mod.is_a? Module

    mod.send :remove_method, name
    self
  end

  def __undefine_on(mod)
    raise ArgumentError unless mod.is_a? Module

    mod.send :undef_method, name
    self
  end
end
