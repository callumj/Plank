require 'json'

class DirtyDocument
  attr_accessor :key
  
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
  
  def to_json
    variables = {}
    self.instance_variables.each do |variable|
      obj_value = self.instance_variable_get(variable)
      
      if (obj_value.instance_of?(DirtyDocument.class))
        obj_value.set_key
        obj_value.save
        variables[variable.to_s] = {:type => "dirty_document", :class => obj_value.class.name, :key => obj_value.key}
      else
        variables[variable.to_s] = obj_value
      end
    end
    variables.to_json
  end
  
  def save
    set_key if @key == nil
    
    DirtyManager.instance.write(self)
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
    file_values = JSON.parse(file_contents)
    file_values.each_key do |key|
      key_sym = key.to_sym
      class_instance.instance_variable_set(key_sym,file_values[key])
    end
    
    class_instance
  end
end