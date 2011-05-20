class User < DirtyDocument
  attr_accessor :name

   has_many :post
  
  def initialize
    super()
  end
end