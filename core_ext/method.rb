class Method
  def bound_to?(obj)
    obj.__id__ == receiver.__id__
  end

  def changed?
    receiver.__method(name) != self
  end

  def current
    cur = receiver.method(name).tap { |m| return self if m == self }
    cur.instance_variable_set :@_origin, cur.owner.__instance_method(sym) unless cur.owner == self.class
    cur
  end

  def origin
    @_origin ||= self
  end

  def receiver_class
    @_receiver_class ||= receiver.class
  end

  def redefine_on_owner(with = nil, &block)
    __redefine_on owner, with, &block
  end

  alias_method :redefine, :redefine_on_owner

  def remove_from_owner
    __remove_from owner
  end

  alias_method :remove, :remove_from_owner

  def singleton?
    owner.singleton?
  end

  alias_method :__unbind, :unbind
  def unbind
    __unbind.tap do |m|
      m.instance_variable_set :@_receiver_class, receiver_class
      m.instance_variable_set :@_origin, origin
    end
  end
  alias_method :unbound, :unbind

  def rebind(obj)
    bound_to?(obj) ? self : unbind.bind(obj)
  end
  alias_method :bind, :rebind
  alias_method :bound_to, :rebind
  alias_method :rebound_to, :rebind

  def undefine_on_owner
    __undefine_on owner
  end

  def undefine_on_receiver
    __undefine_on receiver.singleton_class
  end

  def undefine_on_receiver_class
    __undefine_on receiver_class
  end

  alias_method :undefine, :undefine_on_receiver

  private

  def __redefine_on(mod, with = nil)
    raise ArgumentError unless mod.is_a? Module

    if block_given?
      with = yield(with == :current ? mod.__instance_method(name) : origin)
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
