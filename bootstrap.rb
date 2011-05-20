#the gems
require 'sinatra'

#load up libs
Dir["#{File.dirname(__FILE__)}/lib/**/*.rb"].each { |f| load(f) }

#load up storage
DirtyManager.set(:storage_path => "/Users/callumj/Dropbox/dbtest")
Dir["#{File.dirname(__FILE__)}/model/**/*.rb"].each { |f| load(f) }
DirtyManager.instance.load_dir

$this_user = User.find(:key => ARGV[0])

#the web app
load "#{File.dirname(__FILE__)}/webapp.rb"