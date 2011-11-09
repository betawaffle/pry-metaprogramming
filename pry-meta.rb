class Class
  def singleton?
    self != ancestors.first
  end
end

module MethodExtensions
  def changed?
    meth  = is_a?(Method) ? receiver.method(name) : owner.instance_method(name)
    meth != self
  end

  def current
    meth = is_a?(Method) ? receiver.method(name) : owner.instance_method(name)
    meth.tap { |m| return self if m == self }
  end

  def origin
    owner.instance_method(name).tap { |m| return self if m == self }
  end

  def redefine_on_owner
    replace_on_owner owner.instance_method(name).tap { |old| break yield(old) if block_given? }
  end

  alias_method :redefine, :redefine_on_owner

  def replace_on_owner(with)
    owner.send(:define_method, name, with)
    current
  end

  alias_method :replace, :replace_on_owner

  def remove_from_owner
    owner.send(:remove_method, name)
    self
  end

  alias_method :remove, :remove_from_owner

  # def singleton
  #   is_a?(Method) ? self : ObjectSpace.each_object(owner) { |o| break o }

  #   receiver.send(:define_singleton_method, name, self)
  #   receiver.method(name)
  # end

  def singleton?
    owner.singleton?
  end

  def undefine_on_owner
    owner.send(:undef_method, name)
    self
  end

  alias_method :undefine, :undefine_on_owner
end

class UnboundMethod
  include MethodExtensions
end

class Method
  include MethodExtensions

  def append_on_receiver(&with)
    redefine_on_receiver do |old|
      lambda do |*a, &b|
        ret = old.bind(self).call(*a, &b)
        with.call(*a, &b)
        ret
      end
    end
  end

  alias_method :append, :append_on_receiver

  def rebind(obj)
    unbind.bind(obj)
  end

  alias_method :bind, :rebind
  alias_method :unbound, :unbind

  def redefine_on_receiver
    replace_on_receiver receiver.method(name).tap { |old| break yield(old) if block_given? }
  end

  def redefine_on_singleton
    replace_on_singleton receiver.class.method(name).tap { |old| break yield(old) if block_given? }
  end

  def replace_on_receiver(with)
    receiver.class.send(:define_method, name, with)
    receiver.method(name)
  end

  def replace_on_singleton(with)
    receiver.send(:define_singleton_method, name, with)
    receiver.method(name)
  end

  def reset!
    redefine_on_receiver
  end
end

=begin
module MethodExtensions
  module Shared


    def singleton?
      owner.singleton?
    end
  end

  module Unbound
    include Shared



    def compatible_with?(other)
      case other
      when UnboundMethod
        return owner == other.owner # FIXME: This is too simplistic
      when Method
        return false
      when Proc
        return true
      end
    end

    def current
      cur = owner.instance_method(name)
      cur == self ? self : cur
    end
  end

  module Bound
    include Shared

    def changed_on_owner?
      owner.instance_method(name) != self.unbind
    end

    def changed_on_receiver?
      receiver.method(name) != self
    end

    alias_method :changed?, :changed_on_receiver?

    def compatible_with?(other)
      case other
      when Method
        return receiver == other.receiver
      when UnboundMethod
        return receiver.is_a? other.owner
      when Proc
        return true
      end
    end

    def current
      cur = receiver.method(name)
      cur == self ? self : cur
    end


  end
end
=end



=begin
class Method
  def append(with = nil)
    assert_not_changed
    old_method = self
    with = with ? yield(old_method) : Proc.new if block_given?
    assert_compatibly with

    case with
    when UnboundMethod
      with = with.bind(receiver)
    when Proc, Method
    else
      raise ArgumentError
    end

    new_method = lambda do |*a, &b|
      ret = old_method.call(*a, &b)
      with.call(*a, &b)
      ret
    end

    redefine! new_method # Assumes method was not changed during yield
  end

  def append_chain(with = nil)
    assert_not_changed
    old_method = self
    with = with ? yield(old_method) : Proc.new if block_given?
    assert_compatibly with

    case with
    when UnboundMethod
      with = with.bind(receiver)
    when Proc, Method
    else
      raise ArgumentError
    end

    new_method = lambda do |*a, &b|
      with.call old_method.call(*a, &b)
    end

    redefine! new_method # Assumes method was not changed during yield
  end

  def prepend(with = nil)
    assert_not_changed
    old_method = self
    with = with ? yield(old_method) : Proc.new if block_given?
    assert_compatibly with

    case with
    when UnboundMethod
      with = with.bind(receiver)
    when Proc, Method
    else
      raise ArgumentError
    end

    new_method = lambda do |*a, &b|
      with.call(*a, &b)
      old_method.call(*a, &b)
    end

    redefine! new_method # Assumes method was not changed during yield
  end

  def redefine(*args, &block)
    assert_not_changed
    redefine! *args, &block
  end

  def redefine!(*args, &block)
    receiver.send(:define_singleton_method, name, *args, &block)
    current
  end

  # def remove!
  # end

  def reset!
    redefine! self
  end
end

class UnboundMethod
  def append(with = nil)
    assert_not_changed
    old_method = self
    with = with ? yield(old_method) : Proc.new if block_given?
    assert_compatibly with

    case with
    when UnboundMethod
      new_method = lambda do |*a, &b|
        ret = old_method.bind(self).call(*a, &b)
        with.bind(self).call(*a, &b)
        ret
      end
    when Proc
      new_method = lambda do |*a, &b|
        ret = old_method.bind(self).call(*a, &b)
        with.call(*a, &b)
        ret
      end
    else
      raise ArgumentError
    end

    redefine! new_method # Assumes method was not changed during yield
  end

  def append_chain(with = nil)
    assert_not_changed
    old_method = self
    with = with ? yield(old_method) : Proc.new if block_given?
    assert_compatibly with

    case with
    when UnboundMethod
      new_method = lambda do |*a, &b|
        with.bind(self).call old_method.bind(self).call(*a, &b)
      end
    when Proc
      new_method = lambda do |*a, &b|
        with.call old_method.bind(self).call(*a, &b)
      end
    else
      raise ArgumentError
    end

    redefine! new_method # Assumes method was not changed during yield
  end

  def prepend(with = nil)
    assert_not_changed
    old_method = self
    with = with ? yield(old_method) : Proc.new if block_given?
    assert_compatibly with

    case with
    when UnboundMethod
      new_method = lambda do |*a, &b|
        with.bind(self).call(*a, &b)
        old_method.bind(self).call(*a, &b)
      end
    when Proc
      new_method = lambda do |*a, &b|
        with.call(*a, &b)
        old_method.bind(self).call(*a, &b)
      end
    else
      raise ArgumentError
    end

    redefine! new_method # Assumes method was not changed during yield
  end

  def redefine(*args, &block)
    assert_not_changed
    redefine! *args, &block
  end

  def redefine!(*args, &block)
    owner.send(:define_method, name, *args, &block)
    current
  end

  def reset!
    redefine! self
  end
end
=end
