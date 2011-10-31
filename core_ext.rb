File.expand_path('../core_ext', __FILE__).tap do |base|
  %w(object module class method unbound_method fiber).each { |f| require File.join(base, f) }
end
