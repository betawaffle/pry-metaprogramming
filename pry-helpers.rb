=begin
def init_require_hooks
  Kernel.module_eval do
    alias_method :__require, :require

    class << self
      def require(file)
        __require(file).tap { after_require(file) }
      end

      def after_require(file, &block)
        return unless file.to_s[0] != '/'

        hook = :"required_#{file.gsub('/', '_')}"

        if block_given?
          define_method(hook, &block)
        elsif respond_to? hook
          send hook
          remove_method hook
        end
      end
    end
  end

  def require(file)
    __require(file).tap { Kernel.after_require(file) }
  end
end

Kernel.instance_eval do
  def after_require(file, &block)
    init_require_hooks
    after_require(file, &block)
  end
end
=end

# def load_hirb
#   require 'hirb'
# rescue LoadError
#   # Missing goodies, bummer
# end

# def init_hirb
#   return unless defined? Hirb

#   extend Hirb::Console

#   Pry.config.print = proc do |output, value|
#     Hirb::View.view_or_page_output(value) || Pry::DEFAULT_PRINT.call(output, value)
#   end

#   Hirb.enable
# end

# Toys methods
# Stealed from https://gist.github.com/807492
=begin
class Array
  def self.toy(n = 10, &block)
    block_given? ? Array.new(n, &block) : Array.new(n) { |i| i + 1 }
  end
end

class Hash
  def self.toy(n = 10)
    Hash[Array.toy(n).zip(Array.toy(n) { |c| (96 + (c + 1)).chr })]
  end
end
=end
