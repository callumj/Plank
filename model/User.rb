class User < DirtyDocument
  attr_accessor :name
  attr_accessor :username

   has_many :post
  
  def initialize
    super()
  end
end