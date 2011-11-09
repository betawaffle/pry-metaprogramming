%w(core_ext).each do |f|
  require File.expand_path("../#{f}", __FILE__)
end
