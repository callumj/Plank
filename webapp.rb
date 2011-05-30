get '/' do
  redirect "/index.html"
end

before do
  
  @page_title = "#{$options[:db_name].capitalize} forum - Plank"
  
  if ($options[:this_user] == nil)
    $options[:this_user] = User.new
    $options[:this_user].name = "No user"
    
    unless (request.path.start_with?("/user_create"))
      redirect("/user_create") if (!(request.path.start_with?("/style.css") || request.path.start_with?("/public") || request.path.start_with?("/__sinatra__")))
    end
  end
end

get '/index.:format' do
  @threads = ForumThread.find()
  @threads = @threads.sort {|x,y| y.created_at.to_s <=> x.created_at.to_s }
  
  erb :index
end

get '/user_create' do
  erb :user_create
end

post '/user_create' do
  #build user and set values
  display_name = params[:display_name]
  user_name = params[:user_name]
  
  new_user = User.new
  new_user.name = display_name
  new_user.username = user_name
  new_user.save
  
  $options[:this_user] = new_user
  
  #write settings to file
  user_settings = {"user_key" => new_user.key}
  user_settings_str = MessagePack.pack(user_settings)
  File.open($options[:user_settings_file], 'w') {|f| f.write(user_settings_str) }
end

get '/thread_create' do
  erb :thread_create
end

post '/thread_create' do
  #inject
  thread_name = params[:thread_name]
  post_message = params[:message]
  
  new_thread = ForumThread.new
  new_thread.title = thread_name
  new_thread.created_at = Time.now
  new_thread.save
  
  thread_post = Post.new
  thread_post.forum_thread = new_thread
  thread_post.user = $options[:this_user]
  thread_post.contents = post_message
  thread_post.created_at = Time.now
  thread_post.save
  
  redirect("/thread/#{new_thread.key.to_s}.html")
end

get '/thread/:key.:format' do
  
  @thread = ForumThread.find(:key => params[:key])
  
  @page_title = "#{@thread.title} on #{@page_title}"
  
  @posts = @thread.post.sort {|a,b| b.created_at_i <=> a.created_at_i}
  
  @most_recent_post = @posts[0]
  
  erb :thread
end

get '/post_create/:key' do
  erb :post_create
end

post '/post_create/:key' do
  thread = ForumThread.find(:key => params[:key])
  
  post = Post.new
  post.forum_thread = thread
  post.user = $options[:this_user]
  post.contents = params[:message]
  post.created_at = Time.now
  post.save
  
  redirect("/thread/#{thread.key.to_s}.html")
end