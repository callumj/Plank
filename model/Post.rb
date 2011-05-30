class Post < DirtyDocument
  attr_accessor :contents
  attr_accessor :created_at_i

   belongs_to :forum_thread
   belongs_to :user
  
  def initialize
    super()
  end
  
  def created_at=(val)
    self.created_at_i = val.to_i
  end
  
  def created_at
    Time.at(self.created_at_i.to_i)
  end
end