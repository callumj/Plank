class ForumThread < DirtyDocument
  attr_accessor :title
  attr_accessor :tags
  attr_accessor :created_at
  
  has_many :post
    
  def initialize
    super()
  end
end