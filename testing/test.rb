load "#{File.dirname(__FILE__)}/bootstrap.rb"

y = ForumThread.first


user = User.first
user = User.new if user == nil
user.save

20.times do |time|
  x = Post.new
  x.forum_thread = y
  x.save
end