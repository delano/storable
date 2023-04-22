I'm updating one of my projects Storable to remove support for Ruby 2.6 and
adding support for 2.7 and 3.2. The purpose of the project is to Marshal Ruby
code and data structures classes into and out of multiple formats (yaml,
json, csv, tsv). Unlike the Marshal library, Storable stores Ruby code
using the original source code, not the compiled bytecode. This allows
the code to be serialized and deserialized across different Ruby
versions. It also allows the code to be edited and reloaded without
having to restart the Ruby interpreter.

It relies relies on the output formatter (e.g. Yajl) for serializing;
but it extends the formatter to support serializing Ruby code to
strings (not bytecode): Proc, Method, UnboundMethod, Class, Module,
Object, lambda, blocks, and more.

It allows you to specify:
- default values and types for the fields
- sensitive fields, which are fields that are never included in any output.
- a Proc that is called to generate the value of the field when it is
deserialized.

The class is written in Ruby and is available on GitHub at
<https://github.com/delano/storable> and as a gem named "storable".

In my next message, I'll describe the task in more detail using a
real-world example.

The Ruby code below documents a series of tests or "tryouts" that I
wrote to show the expected behaviour of the class. It's the first of
several tryout files that I'm writing for this project. It uses a test
framework called "tryout" that I wrote where the test files are simply
well-documented Ruby code. It's starts with several class definitions
and then a series of tests in the following format:

## Description of the test

RUBY_CODE
# => Expected result

## should raise a RuntimeError if `file` is set and `lines` is a non Range

ps = ProcString.new "do\n false\n end"
ps.file = "to_proc_test"
ps.lines = 100
begin
  ps.to_proc
rescue RuntimeError
  :success
end
# => :success

The tests are run by the try command, which is installed when you install the "tryouts" gem. You can run the tests by running: `try -v 10_basic_usage_tryouts.rb`. In my next message, I'll show you the content of the first tryouts file.

For the purposes of this task, we can simply treat tryouts as a
blackbox that takes a Ruby file as input and produces a report as
output. The report is a list of the tests that were run and the
results of those tests. Example output (with line numbers from the
original test definitions).

     ## should fail if #file is set and #lines is a non Range
39   ps = ProcString.new "do\n false\n end"
40   ps.file = "to_proc_test"
41   ps.lines = 100
42   begin
43     ps.to_proc
44   rescue RuntimeError
45     :success
46   end
47   #=> :success
     ==  :success

require 'storable'

class ::A < Storable
  field :one => String
  field :two => Integer
  field :three => Time
  field :four => Boolean
end
class ::B < Storable
  field :one => String
  field :two
  field :three => Time
end
class ::C < Storable
  field :calc => Proc
end
class ::D < A
  field :five
  sensitive_fields :five
end
class Explicit < Storable
  field :six, :class => Symbol, :default => :guesswork
  field :seven, :class => Symbol, :meth => :someval
  def someval
    :anything
  end
end

## Has instance methods

A.instance_methods(false).collect(&:to_s).sort
# => ["four", "four=", "one", "one=", "three", "three=", "two", "two="]

## "Storable objects have a default initialize method"

a = A.from_array "string", 1, Time.parse("2010-03-04 23:00"), true
[a.one, a.two, a.three, a.four]
# => ["string", 1, Time.parse("2010-03-04 23:00"), true]

## Supports to_array

a = A.from_array "string", 1, Time.parse("2010-03-04 23:00"), true
a.to_array
# => ["string", 1, Time.parse("2010-03-04 23:00"), true]

## "Field types are optional"

b = B.from_array "string", 1, Time.parse("2010-03-04 23:00")
b = B.from_json b.to_json
[b.one, b.two, b.three]
# => ["string", 1, Time.parse("2010-03-04 23:00")]

## "Can restore a proc"

calc = Proc.new do
  2+2
end
c = C.from_array calc
c= C.from_json c.to_json
c.calc.call
# => 4

## Can specify a sensitive instance

d = D.new
d.five = 100
d.sensitive!
d.sensitive?
# => true

## Supports sensitive fields

d = D.new
d.five = 100
d.sensitive!
d2 = d.to_hash
d2[:five]
# => nil

## Sensitive fields don't appear at as nil in to_array

d = D.new
d.five = 100
d.sensitive!
d.to_array.size

## 4

## Supports inheritence

d = D.new
d.one = 100
d2 = d.to_hash
d2[:one]
# => 100

## Can take a value from opt[:default]

explicit = Explicit.new
explicit.six
# => :guesswork

## Can take a value from opt[:default]

explicit = Explicit.new
explicit.seven
# => :anything
