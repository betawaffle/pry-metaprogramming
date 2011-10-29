base = File.expand_path("../core_ext", __FILE__)

%w(object module class method unbound_method).each { |f| require "#{base}/#{f}" }
# Dir[File.expand_path('../core_ext', __FILE__)].each { |f| require f }
