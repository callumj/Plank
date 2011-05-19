class Post < DirtyDocument
  attr_accessor :contents

   belongs_to :forum_thread
  
  def initialize
    super()
    @contents = "xxxx"
  end
end