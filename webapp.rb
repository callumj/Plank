get '/' do
  redirect "/index.html"
end

get '/index.:format' do
  @threads = ForumThread.find()
  @threads = @threads.sort {|x,y| y.created_at.to_s <=> x.created_at.to_s }
  
  erb :index
end

get '/post/:key.format' do
  @post = ForumThread.find(:key => params[:key])
  
end