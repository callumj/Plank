class DirtyManager
  @@instance = nil
  attr_accessor :settings
  attr_accessor :class_collection
  
  def initialize(args = {})
    @settings = {}
    @class_collection = {}
    @settings[:storage_path] = args[:storage_path] if args[:storage_path] != nil
    
    @@instance = self if @@instance == nil
    
    @active_thread = nil
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
    class_name_san = DirtyManager.class_to_str(class_obj)
    folder_path = "#{@settings[:storage_path]}/#{class_name_san}"
    puts folder_path
    Dir.mkdir(folder_path) unless File.exists?(folder_path)
    
    #dump
    serialized_value = class_obj.to_file()
    
    #save internally
    index(class_obj)
    
    #write
    File.open("#{folder_path}/#{class_obj.key}.data", 'w') {|f| f.write(serialized_value) }
  end
  
  def load_dir()
    Dir["#{@settings[:storage_path]}/*/*.data"].each do |file|
      found_obj = DirtyDocument.restore(file)
      index(found_obj)
    end
  end
  
  def start_dir_loader
    @active_thread.stop if @active_thread != nil
    
    @active_thread = Thread.new(self) { |thisObj|        
        while (true)
          self.load_dir()
          sleep 5
        end
      }
  end
  
  def find_class(class_name, key)
    return nil unless @class_collection.key?(class_name)
    @class_collection[class_name][:key][key]
  end
  
  def index(class_obj)
    class_name = DirtyManager.class_to_str(class_obj)
    @class_collection[class_name] = {} unless @class_collection.key?(class_name)
    @class_collection[class_name][:key] = {} unless @class_collection[class_name].key?(:key)
    @class_collection[class_name][:key][class_obj.key] = class_obj
  end
  
  def key_exists?(class_kind, key)
    class_str = ""
    if (class_kind.kind_of?(String))
      class_str = class_kind
    else
      class_str = DirtyManager.class_to_str(class_kind)
    end
    @class_collection.key?(class_str) && @class_collection[class_str][:key].key?(key)
  end
  
  def DirtyManager.class_to_str(class_gen)
    class_name = class_gen.class.name unless class_gen.kind_of?(String)
    class_name = class_gen if class_gen.kind_of?(String)
    class_name_san = class_name.gsub(/[A-Z]/) { |match| "_#{match.downcase}" }
    class_name_san = class_name_san[1,class_name_san.length] if class_name_san[0,1].eql?("_")
  end
end