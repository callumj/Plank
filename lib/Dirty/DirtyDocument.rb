require 'json'

class DirtyDocument
  attr_accessor :key
  @@parent_classes = []
  @@children_classes = []
  @parents = {}
  @children = {}
  @init_done = false
  
  def initialize
    super
    init_variables
  end
  
  def init_variables
    @parents = {} if @parents == nil
    @parents["refs"] = {} unless (@parents.key?("refs") && @parents["refs"] != nil)
    @parents["resolved"] = {} unless (@parents.key?("resolved") && @parents["resolved"] != nil)
    
    @children = {} if @children == nil
    @children["refs"] = {} unless (@children.key?("refs") && @children["refs"] != nil)
    @children["resolved"] = {} unless (@children.key?("resolved") && @children["resolved"] != nil)
    
    
    @init_done = true
  end
  
  def parents_resolved
    return {} unless @parents.key?("resolved")
    @parents["resolved"]
  end
  
  def parents_refs
    return {} unless @parents.key?("refs")
    @parents["refs"]
  end
  
  def method_missing(m, *args, &block)
    init_variables unless @init_done == true
    #detect if requesting a related obj
    clean_name = m.to_s.gsub(/\W/,"").downcase
    super(m, *args, &block) unless (@@parent_classes.include?(clean_name) || @@children_classes.include?(clean_name))
    
    prevent_super = m.to_s[m.length - 1, m.length].eql?(".")
    
    m = m.to_s[0, m.length - 1] if prevent_super
    
    if (m.to_s[m.length - 1, m.length].eql?("=") || m.to_s[m.length - 2, m.length].eql?("<<"))
      args[0].set_key if args[0].kind_of?(DirtyDocument)
      
      this_safe_name = DirtyManager.class_to_str(self)
      
      if @@parent_classes.include?(clean_name)
        @parents["resolved"][clean_name] = args[0]
        @parents["refs"][clean_name] = args[0].key
        
        args[0].send("#{this_safe_name}<<.",self) unless prevent_super
      elsif @@children_classes.include?(clean_name)
        @children["resolved"][clean_name] = [] unless @children["resolved"].key?(clean_name)
        @children["refs"][clean_name] = [] unless @children["refs"].key?(clean_name)
        if (m.to_s[m.length - 2, m.length].eql?("<<"))
          @children["resolved"][clean_name] << args[0]
          @children["refs"][clean_name] << args[0].key
        elsif (m.to_s[m.length - 1, m.length].eql?("="))
          @children["resolved"][clean_name] = [args[0]]
          @children["refs"][clean_name] = [args[0].key]
        end
        
        
        args[0].send("#{this_safe_name}=.",self) unless prevent_super
      end
    else
      if @@parent_classes.include?(clean_name)
        #check if we need to load it or if we already have it
        return @parents["resolved"][clean_name] if (@parents["resolved"].key?(clean_name) && @parents["resolved"][clean_name] != nil)
        #need to ask for it from DirtyManager and load it in
        return nil unless @parents["refs"].key?(clean_name)
        return nil unless DirtyManager.instance.key_exists?(clean_name, @parents["refs"][clean_name])
        @parents["resolved"][clean_name] = DirtyManager.instance.find_class(clean_name, @parents["refs"][clean_name])
      elsif @@children_classes.include?(clean_name)
        #check if we need to load it or if we already have it
        return @children["resolved"][clean_name] if (@children["resolved"].key?(clean_name) && @children["resolved"][clean_name] != nil)
        
        stor_array = []
        
        return [] unless @children["refs"].key?(clean_name)
        @children["refs"][clean_name].each do |key|
          r_obj = DirtyManager.instance.find_class(clean_name, key)
          stor_array << r_obj if (r_obj != nil && !(@children["refs"][clean_name].include?(r_obj)))
        end
        
        stor_array
      end
    end
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
            
      if (obj_value.eql?(@parents))
        #strip the resolved
        obj_value = @parents.clone
        obj_value["resolved"] = nil
      elsif (obj_value.eql?(@children))
        obj_value = @children.clone
        obj_value["resolved"] = nil
      end
      
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
    this_safe_name = DirtyManager.class_to_str(self.new)
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