class Module
  alias_method :__instance_method, :instance_method

  def instance_method(sym)
    __instance_method(sym).tap do |m|
      next unless m.owner != self

      m.instance_variable_set :@_origin, m.owner.__instance_method(sym)
      m.instance_variable_set :@_receiver_class, self
    end
  end
end
