class ForumThread < DirtyDocument
  attr_accessor :title
  attr_accessor :tags
  
  def initialize
    super()
    @title = "Untitled post"
    @tags = ["Hello","how", "are","you"]
  end
end