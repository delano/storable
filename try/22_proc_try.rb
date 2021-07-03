require 'proc_source'
require 'json'
require 'pry'

# NOTE: These tests were converted from the specs in
#       https://github.com/notro/storable
#

def self.block_method(&block)
  @block = block
end


## should handle a simple one line proc with brackets
p = Proc.new { false }
p.source
#=> "{ false }\n"

## should handle a simple multiline proc with brackets
p = Proc.new {
false
}
p.source
#=> "{\nfalse\n}\n"

## should handle a simple one line proc with do/end
p = Proc.new do false end
p.source
#=> "do false end\n"

## should handle a simple multiline proc with do/end
p = Proc.new do
false
end
p.source
#=> "do\nfalse\nend\n"

## should handle a more complicated proc with brackets
p = Proc.new {
print 'hello'
(1..10).each { |i|
print i
}
}
p.source
#=> "{\nprint 'hello'\n(1..10).each { |i|\nprint i\n}\n}\n"

## should handle a more complicated proc with do/end
p = Proc.new do
print 'hello'
(1..10).each { |i|
print i
}
end
p.source
#=> "do\nprint 'hello'\n(1..10).each { |i|\nprint i\n}\nend\n"

## should handle a {} block passed to a method
block_method {
false
}
@block.source
#=> "{\nfalse\n}\n"

## should handle a do/end block passed to a method
block_method do
false
end
@block.source
#=> "do\nfalse\nend\n"

## should handle hash assignment {:a=>1} in code with do/end singleline block
p = Proc.new do hash = {:a=>1} end
p.source.gsub(/ +/, " ").strip
#=> "do hash = {:a=>1} end"

## should handle hash assignment {:a=>1} in code with {} singleline block
p = Proc.new { hash = {:a=>1} }
p.source
#=> "{ hash = {:a=>1} }\n"

## should handle hash assignment {:a=>1} in code with do/end multiline block
p = Proc.new do
hash = {:a=>1}
end
p.source
#=> "do\nhash = {:a=>1}\nend\n"

## should handle hash assignment {:a=>1} in code with {} multiline block
p = Proc.new {
hash = {:a=>1}
}
p.source
#=> "{\nhash = {:a=>1}\n}\n"

## should handle comments in proc
p = Proc.new {
# comment
true # comment
# comment
}
p.source
#=> "{\n# comment\ntrue # comment\n# comment\n}\n"

## should handle if, elsif, else statement
p = Proc.new {
if false
elsif true
else
end
}
p.source
#=> "{\nif false\nelsif true\nelse\nend\n}\n"

## #lines should be correct for one line proc
@line = __LINE__ + 1
p = Proc.new { false }
p.source.lines
#=> (@line..@line)

## #lines should be correct for multiline proc
@before = __LINE__
p = Proc.new {
  puts "hello"
  puts "goodbye"
  false
}
@after = __LINE__
ps = p.source.lines
#=> (@before+1..@after-1)

## #file should be correct
p = Proc.new { false }
p.source.file
#=> __FILE__

## Proc#line should return correct line
@line = __LINE__ + 1
p = Proc.new { false }
p.line
#=> @line

## Proc#file should return correct filename
p = Proc.new { false }
p.file
#=> __FILE__


## Proc.from_string test
Proc.from_string("{ 1 }").call
#=> 1

## Proc.from_string test
Proc.from_string("do 2 end").call
#=> 2

## Proc.from_string test
Proc.from_string("{\n3\n}").call
#=> 3

## Proc.from_string test
Proc.from_string("do\n4\nend").call
#=> 4

## Proc.from_string test
Proc.from_string("{ if true\n  5\nelse\n  6\nend }").call
#=> 5

## Proc.from_string test
Proc.from_string("{ p = proc { 7 }; p.call}").call
#=> 7


## should handle procs with argument: <none>
@p = Proc.new { true }
Proc.from_string(@p.source).arity
#=> @p.arity

## should handle procs with argument: ||
@p = Proc.new { || true }
Proc.from_string(@p.source).arity
#=> @p.arity

## should handle procs with argument: |a|
@p = Proc.new { |a| true }
Proc.from_string(@p.source).arity
#=> @p.arity

## should handle procs with argument: |a,b|
@p = Proc.new { |a,b| true }
Proc.from_string(@p.source).arity
#=> @p.arity

## should handle procs with argument: |a,b,c|
@p = Proc.new { |a,b,c| true }
Proc.from_string(@p.source).arity
#=> @p.arity

## should handle procs with argument: |*a|
@p = Proc.new { |*a| true }
Proc.from_string(@p.source).arity
#=> @p.arity

## should handle procs with argument: |a,*b|
@p = Proc.new { |a,*b| true }
Proc.from_string(@p.source).arity
#=> @p.arity



## Marshal fails on eval'd proc
p1 = Kernel.eval "Proc.new { false }"
begin
  Marshal.dump p1
rescue RuntimeError
  :error_raised
end
#=> :error_raised

## Marshal should work with simple proc
@p1 = Proc.new do false end
@p2 = Marshal.load Marshal.dump(@p1)
[@p1.source, @p1.call, @p1.source_descriptor]
#=> [@p2.source, @p2.call, @p2.source_descriptor]

## Marshal should work with more complex proc
@p1 = Proc.new do |a,b,c,d|
  sum = 0
  (1..10).each do |i|
    sum += a*i + b*i + c*i + d*i
  end
  sum
end
@p2 = Marshal.load(Marshal.dump(@p1))
[@p2.source, @p1.call(2,3,5,7), @p2.call(2,3,5,7)]
#=> [@p1.source, 935, 935]


## JSON fails on eval'd proc
p1 = Kernel.eval "Proc.new { false }"
begin
  p1.to_json
rescue RuntimeError
  :error_raised
end
#=> :error_raised

## JSON should work with simple proc
l1 = __LINE__ + 1
p1 = Proc.new do false end
p1_j = JSON.generate p1
p2 = JSON.parse p1.to_json
[
  p1_j.match(/do false end/m).nil?,
  p1_j.match(/#{__FILE__}.*#{l1},#{l1}/m).nil?,
  p2.inspect.match(/#{__FILE__}:#{l1}/m).nil?,
  p1.call,
  p2[:call]
]
#=> [false, false, false, false, false]

## JSON should work with more complex proc
l1 = __LINE__ + 1
@p1 = Proc.new do |a,b,c,d|
  sum = 0
  (1..10).each do |i|
    sum += a*i + b*i + c*i + d*i
  end
  sum
end
l2 = __LINE__ - 1
p1_j = JSON.generate @p1
p2 = JSON.parse @p1.to_json
val1 = @p1.call(2,3,5,7)
[
  p1_j.match(/sum = 0.*#{__FILE__}.*#{l1},#{l2}/m).nil?,
  p2.inspect.match(/#{__FILE__}:#{l1}/m).nil?,
  p2[:source],
  val1,
  p2.call(2,3,5,7)
]
#=> [false, false, @p1.source, 935, 935]
