require 'json'

class DirtyDocument
  attr_accessor :key
  attr_accessor :parents
  @@parent_classes = []
  @@children_classes = []
  @parents = {}
  
  def initialize
    super
    init_variables
  end
  
  def init_variables
    @parents = {} if @parents == nil
  end
  
  def method_missing(m, *args, &block)
    init_variables if @parents == nil
    
    #detect if requesting a related obj
    clean_name = m.to_s.gsub(/\W/,"").downcase
    this_safe_name = DirtyManager.class_to_str(self.class.name)
    
    op_mode = nil
    rel_mode = nil
    
    if (m.to_s.include?("="))
      op_mode = :assignment
    else
      op_mode = :fetch
    end
    
    if (@@parent_classes.include?(clean_name))
      rel_mode = :parent
    elsif (@@children_classes.include?(clean_name))
      rel_mode = :child
    else
      puts "help"
      return super(m, *args, &block)
    end
    
    
    if op_mode == :fetch
      if rel_mode == :parent
        return nil if @parents[clean_name] == nil
        return DirtyManager.instance.find_class(clean_name, @parents[clean_name])
      elsif rel_mode == :child
        results = []
        DirtyManager.instance.class_collection[clean_name][:key].values.each do |obj|
          results << obj if obj.parents[this_safe_name].eql?(self.key)
        end
        return results
      end
    elsif op_mode == :assignment
      if rel_mode == :parent
        @parents[clean_name] = args[0].key
        return true
      end    
    end
    
    return nil
  end
  
  def set_key
    if @key == nil
      @key = "#{Time.now.to_i.to_s}_#{rand(10000)}"
      count = 0
      while (DirtyManager.instance.key_exists?(self.class, @key)) do
        @key = "#{Time.now.to_i.to_s}_#{rand(1000)}"
        count = count + 1
        break if count > 20
      end
      
      #final check
      raise "Key collision" if DirtyManager.instance.key_exists?(self.class, @key)
    end
  end
  
  def to_file
    variables = {}
    self.instance_variables.each do |variable|
      obj_value = self.instance_variable_get(variable)      
      variables[variable.to_s] = obj_value
    end
    MessagePack.pack(variables)
  end
  
  def save
    set_key if @key == nil
    
    DirtyManager.instance.write(self)
  end
  
  def DirtyDocument.belongs_to(class_kind)
    @@parent_classes << class_kind.downcase.to_s unless @@parent_classes.include?(class_kind.downcase.to_s)
  end
  
  def DirtyDocument.has_many(class_kind)
    @@children_classes << class_kind.downcase.to_s unless @@children_classes.include?(class_kind.downcase.to_s)
  end
  
  def DirtyDocument.restore(file)
    #read in file
    file_contents = ""
    File.open(file, 'r') do |f1|  
      while line = f1.gets  
        file_contents << line  
      end  
    end
    
    #detect class
    clean_path = file.gsub(File.basename(file),"")
    clean_path = clean_path[0,clean_path.length - 1]
    class_name = clean_path[clean_path.rindex("/") + 1,clean_path.length]
    
    class_name = class_name.gsub(/(_[a-z])/) { |match| match[1,match.length].upcase }
    class_name[0] = class_name[0].to_s.capitalize
    
    class_target = Kernel.const_get(class_name)
    
    class_instance = class_target.new
    
    #build class
    file_values = MessagePack.unpack(file_contents)
    file_values.each_key do |key|
      key_sym = key.to_sym
      class_instance.instance_variable_set(key_sym,file_values[key])
    end
    
    class_instance.init_variables
        
    class_instance
  end
  
  def DirtyDocument.first
    this_safe_name = DirtyManager.class_to_str(self.name)
    return nil unless (DirtyManager.instance.class_collection.key?(this_safe_name) && DirtyManager.instance.class_collection[this_safe_name].key?(:key))
    return DirtyManager.instance.class_collection[this_safe_name][:key].values[0]
  end
  
  def DirtyDocument.findOne(args = {})
    results = self.find(args)
    return nil if results == nil
    if (results.kind_of?(Array))
      if (results.size == 0)
        return nil
      else
        return results[0]
      end
    end
    return results
  end
  
  def DirtyDocument.find(args = {})
    this_safe_name = DirtyManager.class_to_str(self.name)
    return [] unless DirtyManager.instance.class_collection.key?(this_safe_name)
    return DirtyManager.instance.class_collection[this_safe_name][:key].values if args.empty?
    
    return DirtyManager.instance.find_class(this_safe_name, args[:key]) if args.key?(:key)
    
    #doing a basic iterate, to be improved later
    results = []
    DirtyManager.instance.class_collection[this_safe_name][:key].each_value do |val|
      args.each_value do |arg|
        field_val = val.send(arg.to_s).to_s
        results << val if field_val.eql?(args[val].to_s)
      end
    end
    results if results.size != 1
    results[0] if results.size == 1
  end
end