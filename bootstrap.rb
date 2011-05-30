#bundler
require "bundler/setup"
require 'optparse'

#the gems
require 'sinatra'
require 'msgpack'

$options = {}

#Parse cmdline options
optparse = OptionParser.new do|opts|
  
  $options[:dbpath] = "#{Dir.pwd}"
  opts.on( '-d', '--dbpath FOLDER', 'Use specific database path' ) do |folder|
    $options[:dbpath] = folder
  end
  
  $options[:dropbox] = nil
  opts.on( '-b', '--dropbox FOLDER', 'Use specific Dropbox location' ) do |folder|
    $options[:dropbox] = folder
  end
end

#Find DB name
clean_path = $options[:dbpath]
clean_path = clean_path[0, clean_path.length - 1] if clean_path[clean_path.length - 1, clean_path.length].eql?("/")
$options[:db_name] = clean_path[clean_path.rindex("/") + 1,clean_path.length]

#attempt to obtain Dropbox root folder from database location
if ($options[:dropbox] == nil)
  path_test = $options[:dbpath]
  while(!(path_test.eql?("/")))
    break if (path_test.match(/\/Dropbox\/*$/) != nil)
    
    path_test = File.expand_path("#{path_test}/..")
  end
  $options[:dropbox] = path_test
end

puts "Using #{$options[:dbpath]} for database(#{$options[:db_name]}) location"
puts "Using #{$options[:dropbox]} for settings location"

real_db_loc = "#{$options[:dbpath]}/plank_db"

Dir.mkdir(real_db_loc) unless File.exists?(real_db_loc)

$options[:user_settings] = {}
$options[:user_settings_file] = "#{$options[:dropbox]}/#{$options[:db_name]}.conf"
#Read in user specific settings
if (File.exists?($options[:user_settings_file]))
  file_contents = ""
  File.open($options[:user_settings_file], 'r') do |f1|  
    while line = f1.gets  
      file_contents << line  
    end  
  end
  
  $options[:user_settings] = MessagePack.unpack(file_contents)
end

#load up libs
Dir["#{File.dirname(__FILE__)}/lib/**/*.rb"].each { |f| load(f) }

#load up storage
DirtyManager.set(:storage_path => real_db_loc)
Dir["#{File.dirname(__FILE__)}/model/**/*.rb"].each { |f| load(f) }
DirtyManager.instance.load_dir
DirtyManager.instance.start_dir_loader

$options[:this_user] = nil
$options[:this_user] = User.findOne(:key => $options[:user_settings]["user_key"]) if $options[:user_settings].key?("user_key")
puts "Could not locate user, will require user creation on access" if $options[:this_user] == nil

#the web app
load "#{File.dirname(__FILE__)}/webapp.rb"