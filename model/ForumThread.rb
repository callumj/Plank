class ForumThread < DirtyDocument
  attr_accessor :title
  attr_accessor :created_at_i
  
  has_many :post
    
  def initialize
    super()
  end
  
  def created_at=(val)
    self.created_at_i = val.to_i
  end
  
  def created_at
    self.created_at_i = Time.now.to_i if self.created_at_i == nil
    Time.at(self.created_at_i)
  end
end