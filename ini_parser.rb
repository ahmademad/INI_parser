class Hash
  def to_obj
    #converts a Ruby hash into a class object. I had used this code in one other project
    #I worked on
    self.each do |k,v|
      if v.kind_of? Hash
        v.to_obj
      end
      # create and initialize an instance variable for this key/value pair
      self.instance_variable_set("@#{k}", v)

      # create the getter that returns the instance variable
      self.class.send(:define_method, k, proc{self.instance_variable_get("@#{k}")})

      # create the setter that sets the instance variable
      self.class.send(:define_method, "#{k}=", proc{|v| self.instance_variable_set("@#{k}", v)})
    end
    return self
  end
  
# returns nil if the method does not exist, instead of throwing an error  
    def method_missing(n)
      self[n.to_s]
    end
    
end

# converts keys of hash from string to symbols
def to_sym hash
  hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
end

def load_config file_path, overrides = []
  
  # overrides are converted to string array
  str_overrides = []
  overrides.each do |over|
    str_overrides.push over.to_s
  end
  overrides = str_overrides
  
  file = File.new file_path, "r"
  config = {}
  group = ""
  attributes = {}
  
  while line = file.gets
    # group
    line.scan /^(\s*)\[(\w+)\](\s*)$/i do |space1, gr, space2|
      if !attributes.empty?
        attributes = to_sym attributes
        config[group] = attributes
      end
      group = gr
      attributes = {}
    end
    
    # assignment
    line.scan /^\s*(\w+)(\<\w+\>)?\s*\=\s*(\")?([a-zA-Z0-9\/,\s]+)(\")?\s*((\;)(.*))?$/i do |attribute, override,quotes1, value, quotes2|
      
      #add quotes back to value
      value_quotes = "#{quotes1}#{value}#{quotes2}".strip
      
      #check whether value is an array, if this is so, it needs to be treated separately
      
      if value_quotes =~ /^((\w+),)+(\w+)/i
        value_quotes = value_quotes.split ','
      end
      
      if !override.nil?
        override = override.gsub("<", "").gsub(">", "")
        if overrides.include? override
          attributes[attribute] = value_quotes
        end
      else
        attributes[attribute] = value_quotes
      end
    end
  end
  
  if !attributes.empty?
    attributes = to_sym attributes
    config[group] = attributes
  end
      
  file.close
    
  return config.to_obj
end


