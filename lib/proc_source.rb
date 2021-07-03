
#
# Based on:
# https://github.com/imedo/background
# https://github.com/imedo/background_lite
# With improvements by:
# https://github.com/notro/storable
#

# RubyToken was removed in Ruby 2.7
if RUBY_VERSION < "2.7"
  require 'irb/ruby-token'
else
  require './lib/core_ext.rb'
end

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

class RubyToken::Token
  # These EXPR_BEG tokens don't have associated end tags
  FAKIES = [
    RubyToken::TkWHEN,
    RubyToken::TkELSIF,
    RubyToken::TkELSE,
    RubyToken::TkTHEN,
  ]

  def name
    @name ||= nil
  end

  def open_tag?
    return false if name.nil? || get_props.nil?
    is_open = (
      (get_props[1] == RubyToken::EXPR_BEG) &&
      (self.class.to_s !~ /_MOD/)  &&  # ignore onliner if, unless, etc...
      (!FAKIES.member?(self.class))
    )
    is_open
  end

  def get_props
    RubyToken::TkReading2Token[name]
  end

end

# Based heavily on code from http://github.com/imedo/background
# Big thanks to the imedo dev team!
#
module ProcSource
  def self.find(filename, start_line=1, block_only=true)
    lines, lexer = nil, nil
    retried = 0
    loop do
      lines = get_lines(filename, start_line)
      return nil if lines.nil?
      if !line_has_open?(lines.join) && start_line >= 0
        start_line -= 1 and retried +=1 and redo
      end
      lexer = RubyLex.new
      lexer.set_input(StringIO.new(lines.join))
      break
    end

    stoken, etoken, nesting = nil, nil, 0

    if RUBY_VERSION < "2.7"
      tokens = lexer.instance_variable_get '@OP'
    else
      lexer.lex
      tokens = lexer.instance_variable_get '@tokens'
    end

    # tokens.each

    while (token = lexer.token) do
      if RubyToken::TkIDENTIFIER === token
        # nothing
      elsif token.open_tag? || RubyToken::TkfLBRACE === token
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

  # A hack for Ruby 1.9, otherwise returns true.
  #
  # Ruby 1.9 returns an incorrect line number
  # when a block is specified with do/end. It
  # happens b/c the line number returned by
  # Ruby 1.9 is based on the first line in the
  # block which contains a token (i.e. not a
  # new line or comment etc...).
  #
  # NOTE: This won't work in cases where the
  # incorrect line also contains a "do".
  #
  def self.line_has_open?(str)
    return true unless RUBY_VERSION >= '1.9' && RUBY_VERSION < '2.0'
    lexer = RubyLex.new
    lexer.set_input(StringIO.new(str))
    success = false
    while token = lexer.token
      case token
      when RubyToken::TkNL
        break
      when RubyToken::TkDO
        success = true
      when RubyToken::TkfLBRACE
        success = true
      when RubyToken::TkCONSTANT
        if token.name == "Proc" &&
           lexer.token.is_a?(RubyToken::TkDOT)
          method = lexer.token
          if method.is_a?(RubyToken::TkIDENTIFIER) &&
             method.name == "new"
            success = true
          end
        end
      end
    end
    success
  end

  def self.get_lines(filename, start_line = 1)
    case filename
      when nil
        nil

      # We're in irb
      when "(irb)"
        IRB.conf[:MAIN_CONTEXT].io.line(start_line .. -2)

      # Or an eval
      when /^\(eval.+\)$/
        EVAL_LINES__[filename][start_line .. -2]

      # Or most likely a .rb file
      else
        # Ruby already parsed this file? (see disclaimer above)
        if defined?(SCRIPT_LINES__) && SCRIPT_LINES__[filename]
          SCRIPT_LINES__[filename][(start_line - 1) .. -1]

        # If the file exists we're going to try reading it in
        elsif File.exist?(filename)
          begin
            File.readlines(filename)[(start_line - 1) .. -1]
          rescue
            nil
          end
        end
    end
  end
end

class Proc  # :nodoc:
  attr_writer :source
  @@regexp = Regexp.new('^#<Proc:0x[0-9A-Fa-f]+@?\s*(.+):(\d+)(.+?)?>$')

  def source_descriptor
    return [@file, @line] if @file && @line

    source_location = nil
    if RUBY_VERSION >= '2.7'
      source_location = *self.source_location
    else
      inspection = inspect
      md = @@regexp.match(inspection)
      exmsg = 'Unable to parse proc inspect (%s)' % inspection
      raise Exception, exmsg if md.nil?
      source_location = md.captures
    end

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

