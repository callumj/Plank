class DirtyManager
  @@instance = nil
  attr_accessor :settings
  attr_accessor :class_collection
  
  def initialize(args = {})
    @settings = {}
    @class_collection = {}
    @settings[:storage_path] = args[:storage_path] if args[:storage_path] != nil
    
    @@instance = self if @@instance == nil
  end
  
  def DirtyManager.instance
    DirtyManager.new if @@instance == nil
    return @@instance
  end
  
  def DirtyManager.set(args)
    target = DirtyManager.instance
    target.settings[:storage_path] = args[:storage_path] if args[:storage_path] != nil
  end
  
  def write(class_obj)
    #create folder
    class_name = class_obj.class.name
    class_name_san = class_name.gsub(/[A-Z]/) { |match| "_#{match.downcase}" }
    class_name_san = class_name_san[1,class_name_san.length] if class_name_san[0,1].eql?("_")
    folder_path = "#{@settings[:storage_path]}/#{class_name_san}"
    Dir.mkdir(folder_path) unless File.exists?(folder_path)
    
    #dump
    serialized_value = class_obj.to_json
    
    #save internally
    index(class_obj)
    
    #write
    File.open("#{folder_path}/#{class_obj.key}.json", 'w') {|f| f.write(serialized_value) }
  end
  
  def load_dir()
    Dir["#{@settings[:storage_path]}/*/*.json"].each do |file|
      found_obj = DirtyDocument.restore(file)
      index(found_obj)
    end
  end
  
  def index(class_obj)
    @class_collection[class_obj.class.name] = {} unless @class_collection.key?(class_obj.class.name)
    @class_collection[class_obj.class.name][class_obj.key] = class_obj
  end
  
  def key_exists?(class_kind, key)
    @class_collection.key?(class_kind.name) && @class_collection[class_kind.name].key?(key)
  end
end