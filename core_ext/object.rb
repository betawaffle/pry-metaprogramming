class Object
  alias_method :__method, :method

  def method(sym)
    __method(sym).tap do |m|
      next unless m.owner != self.class

      m.instance_variable_set :@_origin, m.owner.__instance_method(sym)
    end
  end
end
