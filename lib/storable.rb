#--
# TODO: Handle nested hashes and arrays. 
# TODO: to_xml, see: http://codeforpeople.com/lib/ruby/xx/xx-2.0.0/README
#++


USE_ORDERED_HASH = (RUBY_VERSION =~ /1.9/).nil?

begin
  require 'json'
rescue LoadError
  # Silently!
end
  
require 'yaml'
require 'fileutils'
require 'time'
  
# Storable makes data available in multiple formats and can
# re-create objects from files. Fields are defined using the 
# Storable.field method which tells Storable the order and 
# name.
class Storable
  require 'storable/orderedhash' if USE_ORDERED_HASH
  unless defined?(SUPPORTED_FORMATS) # We can assume all are defined
    VERSION = "0.5.4"
    NICE_TIME_FORMAT  = "%Y-%m-%d@%H:%M:%S".freeze 
    SUPPORTED_FORMATS = [:tsv, :csv, :yaml, :json, :s, :string].freeze 
  end
  
  # This value will be used as a default unless provided on-the-fly.
  # See SUPPORTED_FORMATS for available values.
  attr_reader :format
  
  # See SUPPORTED_FORMATS for available values
  def format=(v)
    v &&= v.to_sym
    raise "Unsupported format: #{v}" unless SUPPORTED_FORMATS.member?(v)
    @format = v
  end
  
  def postprocess
  end
  
  # TODO: from_args([HASH or ordered params])
  
  # Accepts field definitions in the one of the follow formats:
  #
  #     field :product
  #     field :product => Integer
  #
  # The order they're defined determines the order the will be output. The fields
  # data is available by the standard accessors, class.product and class.product= etc...
  # The value of the field will be cast to the type (if provided) when read from a file. 
  # The value is not touched when the type is not provided. 
  def self.field(args={})
    # TODO: Examine casting from: http://codeforpeople.com/lib/ruby/fattr/fattr-1.0.3/
    args = {args => nil} unless args.kind_of?(Hash)

    args.each_pair do |m,t|
      
      [[:@@field_names, m], [:@@field_types, t]].each do |tuple|
        class_variable_set(tuple[0], []) unless class_variable_defined?(tuple[0])
        class_variable_set(tuple[0], class_variable_get(tuple[0]) << tuple[1])
      end
      
      next if method_defined?(m)
      
      define_method(m) do instance_variable_get("@#{m}") end
      define_method("#{m}=") do |val| 
        instance_variable_set("@#{m}",val)
      end
    end
  end
  
  # Returns an array of field names defined by self.field
  def self.field_names
    class_variable_get(:@@field_names)
  end
  # Returns an array of field names defined by self.field
  def field_names
    self.class.send(:class_variable_get, :@@field_names)
  end
  # Returns an array of field types defined by self.field. Fields that did 
  # not receive a type are set to nil. 
  def self.field_types
    class_variable_get(:@@field_types)
  end
  # Returns an array of field types defined by self.field. Fields that did 
  # not receive a type are set to nil.
  def field_types
    self.class.send(:class_variable_get, :@@field_types)
  end

  # Dump the object data to the given format. 
  def dump(format=nil, with_titles=false)
    format &&= format.to_sym
    format ||= 's' # as in, to_s
    raise "Format not defined (#{format})" unless SUPPORTED_FORMATS.member?(format)
    send("to_#{format}", with_titles) 
  end
  
  def to_string(*args)
    to_s(*args)
  end
  
  # Create a new instance of the object using data from file. 
  def self.from_file(file_path, format='yaml')
    raise "Cannot read file (#{file_path})" unless File.exists?(file_path)
    raise "#{self} doesn't support from_#{format}" unless self.respond_to?("from_#{format}")
    format = format || File.extname(file_path).tr('.', '')
    me = send("from_#{format}", read_file_to_array(file_path))
    me.format = format
    me
  end
  # Write the object data to the given file. 
  def to_file(file_path=nil, with_titles=true)
    raise "Cannot store to nil path" if file_path.nil?
    format = File.extname(file_path).tr('.', '')
    format &&= format.to_sym
    format ||= @format
    Storable.write_file(file_path, dump(format, with_titles))
  end

  # Create a new instance of the object from a hash.
  def self.from_hash(from={})
    return nil if !from || from.empty?
    me = self.new
    me.from_hash(from)
  end
  
  def from_hash(from={})
    fnames = field_names
    fnames.each_with_index do |key,index|
      
      stored_value = from[key] || from[key.to_s] # support for symbol keys and string keys
      
      # TODO: Correct this horrible implementation 
      # (sorry, me. It's just one of those days.) -- circa 2009-09-15
      
      if field_types[index] == Array
        ((value ||= []) << stored_value).flatten 
      elsif field_types[index].kind_of?(Hash)
        
        value = stored_value
      else
        
        # SimpleDB stores attribute shit as lists of values
        ##value = stored_value.first if stored_value.is_a?(Array) && stored_value.size == 1
        value = (stored_value.is_a?(Array) && stored_value.size == 1) ? stored_value.first : stored_value
        
        if field_types[index] == Time
          value = Time.parse(value)
        elsif field_types[index] == DateTime
          value = DateTime.parse(value)
        elsif field_types[index] == TrueClass
          value = (value.to_s == "true")
        elsif field_types[index] == Float
          value = value.to_f
        elsif field_types[index] == Integer
          value = value.to_i
        elsif field_types[index].kind_of?(Storable) && stored_value.kind_of?(Hash)
          # I don't know why this is here so I'm going to raise an exception
          # and wait a while for an error in one of my other projects. 
          #value = field_types[index].from_hash(stored_value)
          raise "Delano, delano, delano. Clean up Storable!"
        end
      end
      
      self.send("#{key}=", value) if self.respond_to?("#{key}=")  
    end

    self.postprocess
    self
  end
  # Return the object data as a hash
  # +with_titles+ is ignored. 
  def to_hash(with_titles=true)
    tmp = USE_ORDERED_HASH ? Storable::OrderedHash.new : {}
    field_names.each do |fname|
      tmp[fname] = self.send(fname)
    end
    tmp
  end
  
  # Create a new instance of the object from YAML. 
  # +from+ a YAML String or Array (split into by line). 
  def self.from_yaml(*from)
    from_str = [from].flatten.compact.join('')
    hash = YAML::load(from_str)
    hash = from_hash(hash) if hash.kind_of?(Hash)
    hash
  end
  def to_yaml(with_titles=true)
    to_hash.to_yaml
  end
  
  # Create a new instance of the object from a JSON string. 
  # +from+ a YAML String or Array (split into by line). 
  def self.from_json(*from)
    from_str = [from].flatten.compact.join('')
    tmp = JSON::load(from_str)
    hash_sym = tmp.keys.inject({}) do |hash, key|
       hash[key.to_sym] = tmp[key]
       hash
    end
    hash_sym = from_hash(hash_sym) if hash_sym.kind_of?(Hash)  
    hash_sym
  end
  def to_json(with_titles=true)
    to_hash.to_json
  end
  
  # Return the object data as a delimited string. 
  # +with_titles+ specifiy whether to include field names (default: false)
  # +delim+ is the field delimiter.
  def to_delimited(with_titles=false, delim=',')
    values = []
    field_names.each do |fname|
      values << self.send(fname.to_s)   # TODO: escape values
    end
    output = values.join(delim)
    output = field_names.join(delim) << $/ << output if with_titles
    output
  end
  # Return the object data as a tab delimited string. 
  # +with_titles+ specifiy whether to include field names (default: false)
  def to_tsv(with_titles=false)
    to_delimited(with_titles, "\t")
  end
  # Return the object data as a comma delimited string. 
  # +with_titles+ specifiy whether to include field names (default: false)
  def to_csv(with_titles=false)
    to_delimited(with_titles, ',')
  end
  # Create a new instance from tab-delimited data.  
  # +from+ a JSON string split into an array by line.
  def self.from_tsv(from=[])
    self.from_delimited(from, "\t")
  end
  # Create a new instance of the object from comma-delimited data.
  # +from+ a JSON string split into an array by line.
  def self.from_csv(from=[])
    self.from_delimited(from, ',')
  end
  
  # Create a new instance of the object from a delimited string.
  # +from+ a JSON string split into an array by line.
  # +delim+ is the field delimiter.
  def self.from_delimited(from=[],delim=',')
    return if from.empty?
    # We grab an instance of the class so we can 
    hash = {}
    
    fnames = values = []
    if (from.size > 1 && !from[1].empty?)
      fnames = from[0].chomp.split(delim)
      values = from[1].chomp.split(delim)
    else
      fnames = self.field_names
      values = from[0].chomp.split(delim)
    end
    
    fnames.each_with_index do |key,index|
      next unless values[index]
      hash[key.to_sym] = values[index]
    end
    hash = from_hash(hash) if hash.kind_of?(Hash) 
    hash
  end

  def self.read_file_to_array(path)
    contents = []
    return contents unless File.exists?(path)
    
    open(path, 'r') do |l|
      contents = l.readlines
    end

    contents
  end
  
  def self.write_file(path, content, flush=true)
    write_or_append_file('w', path, content, flush)
  end
  
  def self.append_file(path, content, flush=true)
    write_or_append_file('a', path, content, flush)
  end
  
  def self.write_or_append_file(write_or_append, path, content = '', flush = true)
    #STDERR.puts "Writing to #{ path }..." 
    create_dir(File.dirname(path))
    
    open(path, write_or_append) do |f| 
      f.puts content
      f.flush if flush;
    end
    File.chmod(0600, path)
  end
end

