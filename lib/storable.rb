#--
# TODO: Handle nested hashes and arrays.
# TODO: to_xml, see: http://codeforpeople.com/lib/ruby/xx/xx-2.0.0/README
#++


USE_ORDERED_HASH = (RUBY_VERSION =~ /^1.9/).nil?

YAJL_LOADED = begin   
  require 'yajl'
  true
rescue LoadError
  false
end

JSON_LOADED = begin
  require 'json' unless YAJL_LOADED
  true
rescue LoadError
  false
end

require 'yaml'
require 'fileutils'
require 'time'

unless defined?(Boolean)
  # Used in field definitions. 
  #
  #     field :name => Boolean
  #
  class Boolean; end
end

# Storable makes data available in multiple formats and can
# re-create objects from files. Fields are defined using the 
# Storable.field method which tells Storable the order and 
# name.
class Storable
  require 'proc_source'  
  require 'storable/orderedhash' if USE_ORDERED_HASH
  unless defined?(SUPPORTED_FORMATS) # We can assume all are defined
    VERSION = "0.6.5"
    NICE_TIME_FORMAT  = "%Y-%m-%d@%H:%M:%S".freeze 
    SUPPORTED_FORMATS = [:tsv, :csv, :yaml, :json, :s, :string].freeze 
  end
  
  @debug = true
  class << self
    attr_accessor :field_names, :field_types, :debug
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
  #     field :product do |val|
  #       # modify val before it's stored. 
  #     end
  #
  # The order they're defined determines the order the will be output. The fields
  # data is available by the standard accessors, class.product and class.product= etc...
  # The value of the field will be cast to the type (if provided) when read from a file. 
  # The value is not touched when the type is not provided. 
  def self.field(args={}, &processor)
    # TODO: Examine casting from: http://codeforpeople.com/lib/ruby/fattr/fattr-1.0.3/
    args = {args => nil} unless args.kind_of?(Hash)

    args.each_pair do |m,t|
      self.field_names ||= []
      self.field_types ||= {}
      self.field_names << m
      self.field_types[m] = t unless t.nil?
      
      unless processor.nil?
        define_method("_storable_processor_#{m}", &processor)
      end
      
      if method_defined?(m) # don't redefine the accessor methods
        STDERR.puts "method exists: #{self}##{m}" if Storable.debug
        next
      end
      
      define_method(m) do instance_variable_get("@#{m}") end
      define_method("#{m}=") do |val| 
        instance_variable_set("@#{m}",val)
      end
    end
  end
  
  def self.has_field?(n)
    field_names.member? n.to_sym
  end
  def has_field?(n)
    self.class.field_names.member? n.to_sym
  end
  
  # +args+ is a list of values to set amongst the fields. 
  # It's assumed that the order values matches the order
  def initialize(*args)
    (self.class.field_names || []).each_with_index do |n,index|
      break if (index+1) > args.size
      self.send("#{n}=", args[index])
    end
  end

  # Returns an array of field names defined by self.field
  def field_names
    self.class.field_names
  end
  # Returns an array of field types defined by self.field. Fields that did 
  # not receive a type are set to nil.
  def field_types
    self.class.field_types
  end

  # Dump the object data to the given format. 
  def dump(format=nil, with_titles=false)
    format &&= format.to_sym
    format ||= :s # as in, to_s
    raise "Format not defined (#{format})" unless SUPPORTED_FORMATS.member?(format)
    send("to_#{format}") 
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
    fnames.each_with_index do |fname,index|
      ftype = field_types[fname] || String
      value_orig = from[fname] || from[fname.to_s]
      
      if ftype == Array
        value = Array === value_orig ? value_orig : [value_orig]
      elsif ftype.kind_of?(Hash)
        value = value_orig
      else
        if    [Time, DateTime].member?(ftype)
          value = ftype.parse(value_orig)
        elsif [TrueClass, FalseClass, Boolean].member?(ftype)
          value = (value_orig.to_s.upcase == "TRUE")
        elsif ftype == Float
          value = value_orig.to_f
        elsif ftype == Integer
          value = value_orig.to_i
        elsif ftype == Proc
          raise "todo"
        else
          value = value_orig
        end
      end
      
      if self.respond_to?("#{fname}=")
        self.send("#{fname}=", value) 
      else
        self.instance_variable_set("@#{fname}", value) 
      end
      
    end

    self.postprocess
    self
  end
  # Return the object data as a hash
  # +with_titles+ is ignored. 
  def to_hash
    tmp = USE_ORDERED_HASH ? Storable::OrderedHash.new : {}
    field_names.each do |fname|
      v = self.send(fname)
      v = process(fname, v) if has_processor?(fname)
      if Array === v
        v = v.collect { |v2| v2.kind_of?(Storable) ? v2.to_hash : v2 } 
      end
      tmp[fname] = v.kind_of?(Storable) ? v.to_hash : v
    end
    tmp
  end
  
  def to_json(*from, &blk)
    hash = to_hash
    if YAJL_LOADED
      ret = Yajl::Encoder.encode(hash)
      #raise "DELANO"
      #ret.force_encoding("ISO-8859-1")
      #p [:to, ret.encoding.name] if ret.respond_to?(:encoding)
      ret
    elsif JSON_LOADED
      hash.to_json(*from, &blk)
    else 
      raise "no JSON parser loaded"
    end
  end
  
  def to_yaml(*from, &blk)
    to_hash.to_yaml(*from, &blk)
  end

  def process(fname, val)
    self.send :"_storable_processor_#{fname}", val
  end
  
  def has_processor?(fname)
    self.respond_to? :"_storable_processor_#{fname}"
  end
  
  # Create a new instance of the object from YAML. 
  # +from+ a YAML String or Array (split into by line). 
  def self.from_yaml(*from)
    from_str = [from].flatten.compact.join('')
    hash = YAML::load(from_str)
    hash = from_hash(hash) if Hash === hash
    hash
  end
  
  # Create a new instance of the object from a JSON string. 
  # +from+ a YAML String or Array (split into by line). 
  def self.from_json(*from)
    from_str = [from].flatten.compact.join('')
    #from_str.force_encoding("ISO-8859-1")
    #p [:from, from_str.encoding.name] if from_str.respond_to?(:encoding)
    if YAJL_LOADED
      tmp = Yajl::Parser.parse(from_str, :check_utf8 => false)
    elsif JSON_LOADED
      tmp = JSON::load(from_str)
    else
      raise "JSON parser not loaded"
    end
    hash_sym = tmp.keys.inject({}) do |hash, key|
       hash[key.to_sym] = tmp[key]
       hash
    end
    hash_sym = from_hash(hash_sym) if hash_sym.kind_of?(Hash)  
    hash_sym
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


class Storable
  # These methods can be used by Storable objects as
  # custom field processors.
  #
  # e.g.
  #
  #     class A < Storable
  #       field :name => String, &hash_proc_processor
  #     end
  #
  module DefaultProcessors
    # Replace a hash of Proc objects with a hash
    # of 
    def hash_proc_processor 
      Proc.new do |procs|
        a = {}
        procs.each_pair { |n,v| 
          a[n] = (Proc === v) ? v.source : v 
        }
        a
      end
    end
    # If the object already has a value for +@id+
    # use it, otherwise return the current digest.
    #
    # This allows an object to have a preset ID. 
    #
    def gibbler_id_processor
      Proc.new do |val|
        @id || self.gibbler
      end
    end
  end
  extend Storable::DefaultProcessors
end

