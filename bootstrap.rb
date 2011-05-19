#load up libs
Dir["#{File.dirname(__FILE__)}/lib/**/*.rb"].each { |f| load(f) }

DirtyManager.set(:storage_path => "/Users/callumj/Dropbox/dbtest")

Dir["#{File.dirname(__FILE__)}/model/**/*.rb"].each { |f| load(f) }