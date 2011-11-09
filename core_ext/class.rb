class Class
  class << self
    def each_singleton
      return to_enum(:each_singleton) unless block_given?

      Class.each_object { |c| yield c if c.singleton? }
    end
  end

  def singleton?
    self != ancestors.first
  end
end
