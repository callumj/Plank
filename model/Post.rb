class Post < DirtyDocument
  attr_accessor :contents
  attr_accessor :created_at

   belongs_to :forum_thread
   belongs_to :user
  
  def initialize
    super()
  end
end