

require 'irb/ruby-lex'
require 'stringio'

SCRIPT_LINES__ = {} unless defined? SCRIPT_LINES__


class ProcString < String
  # Filename where the proc is defined
  attr_accessor :file

  # Range of lines where the proc is defined. e.g. (12..16)
  attr_accessor :lines
  attr_accessor :arity, :kind

  # Return a Proc object
  # If #lines and #file is specified, these are tied to the proc.
  def to_proc(kind="proc")
    if @file && @lines
      raise "#lines must be a range" unless @lines.kind_of? Range
      result = eval("#{kind} #{self}", binding, @file, @lines.min)
    else
      result = eval("#{kind} #{self}")
    end
    result.source = self
    result
  end

  # Return a lambda
  def to_lambda
    to_proc "lambda"
  end
end


# Based heavily on code from http://github.com/imedo/background
# Big thanks to the imedo dev team!
#
module ProcSource

  def self.find(filename, start_line=1, block_only=true)
    lines = nil
    lexer = nil

    retried = 0
    loop do
      lines = get_lines(filename, start_line)
      return if lines.nil?

      if !line_has_open?(lines.join) && start_line >= 0
        start_line -= 1 and retried +=1 and redo
      end
      lines_str = lines.join
      sio = StringIO.new(lines_str)
      lexer = RubyLex.new

      if RUBY_VERSION >= "3.0"
        lexer.set_input(sio, context: {})
      else
        lexer.
        set_input(sio)
      end
      break
    end

    stoken, etoken, nesting = nil, nil, 0

    lexer.lex
    tokens = lexer.instance_variable_get '@tokens'

    # tokens.each

    while (token = tokens) do
      # require 'pry'; binding.pry
      if token.is_a?(Array)
        p token
      elsif RubyToken::TkIDENTIFIER === token
        # nothing
      elsif RubyToken::TkfLBRACE === token
        nesting += 1
        stoken = token if nesting == 1
      elsif RubyToken::TkEND === token || RubyToken::TkRBRACE === token
        if nesting == 1
          etoken = token
          break
        end
        nesting -= 1
      elsif RubyToken::TkLBRACE === token
        nesting += 1
      elsif RubyToken::TkBITOR === token && stoken
        # nothing
      elsif RubyToken::TkNL === token && stoken && etoken
        break if nesting <= 0
      else
        # nothing
      end
    end

    lines = lines[stoken.line_no-1 .. etoken.line_no-1]

    # Remove the crud before the block definition.
    if block_only
      spaces = lines.last.match(/^\s+/)[0] rescue ''
      lines[0] = spaces << lines[0][stoken.char_no .. -1]
    end
    ps = ProcString.new lines.join
    ps.file = filename
    ps.lines = start_line .. start_line+etoken.line_no-1
    ps
  end

  def self.get_lines(filename, start_line = 1)
    nil
  end
end

class Proc  # :nodoc:
  attr_writer :source
  @@regexp = Regexp.new('^#<Proc:0x[0-9A-Fa-f]+@?\s*(.+):(\d+)(.+?)?>$')

  def source_descriptor
    return [@file, @line] if @file && @line

    source_location = *self.source_location

    file, line = *source_location
    @file, @line = [file, line.to_i]
  end

  def source
    @source ||= ProcSource.find(*self.source_descriptor)
  end

  def line
    source_descriptor
    @line
  end

  def file
    source_descriptor
    @file
  end

  # Dump to Marshal format.
  #   p = Proc.new { false }
  #   Marshal.dump p
  def _dump(limit)
    raise "can't dump proc, #source is nil" if source.nil?
    str = Marshal.dump(source)
    str
  end

  # Load from Marshal format.
  #   p = Proc.new { false }
  #   Marshal.load Marshal.dump p
  def self._load(str)
    @source = Marshal.load(str)
    @source.to_proc
  end

  # Dump to JSON string
  def to_json(*args)
    raise "can't serialize proc, #source is nil" if source.nil?
    {
      'json_class' => self.class.name,
      'data'       => [source.to_s, source.file, source.lines.min, source.lines.max]
    }.to_json#(*args)
  end

  def self.json_create(o)
    s, file, min, max = o['data']
    ps = ProcString.new s
    ps.file = file
    ps.lines = (min..max)
    ps.to_proc
  end

  # Create a Proc object from a string of Ruby code.
  # It's assumed the string contains do; end or { }.
  #
  #     Proc.from_string("do; 2+2; end")
  #
  def self.from_string(str)
    eval "Proc.new #{str}"
  end

end

if $0 == __FILE__
  def store(&blk)
    @blk = blk
  end

  store do |blk|
    puts "Hello Rudy1"
  end

  a = Proc.new() { |a|
    puts  "Hello Rudy2"
  }

  b = Proc.new() do |b|
    puts { "Hello Rudy3" } if true
  end

  puts @blk.inspect, @blk.source
  puts [a.inspect, a.source]
  puts b.inspect, b.source

  proc = @blk.source.to_proc
  proc.call(1)
end
