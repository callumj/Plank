class User < DirtyDocument
  attr_accessor :name
  attr_accessor :username
  attr_accessor :email

   has_many :post
  
  def initialize
    super()
  end
end