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
  
  def to_json(*a)
    {"title" => @title, "created_at" => @created_at_i, "restore_at" => @restore_time.to_i}.to_json(*a)
  end
  
  def all_emails
    emails = []
    self.post.each do |post_obj|
      emails << post_obj.user.email if (post_obj.user != nil && !(post_obj.user.email.empty?) && !(emails.include?(post_obj.user.email)))
    end
    emails
  end
end