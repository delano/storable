#require 'pry'
require 'proc_source'

# NOTE: These tests were converted from the specs in
#       https://github.com/notro/storable
#

@subject = ProcString.new "{ false }"
subject = ProcString.new "{ false }"


## string should be set
@subject
#=> "{ false }"

## #file can be set
@subject.file = "test.rb"
@subject.file
#=> "test.rb"

## #lines can be set
@subject.lines = 1..10
#=> (1..10)


## should create a proc
ps = ProcString.new "do\n false\n end"
ps.to_proc.class
#=> Proc

## should connect #file and #lines to the proc
ps = ProcString.new "do\n false\n end"
ps.file = "to_proc_test"
ps.lines = (100..102)
ps.to_proc.inspect.index('to_proc_test:100').nil?
#=> false

## should fail if #file is set and #lines is a non Range
ps = ProcString.new "do\n false\n end"
ps.file = "to_proc_test"
ps.lines = 100
begin
  ps.to_proc
rescue RuntimeError
  :success
end
#=> :success

## should create a lambda
## Test is from: http://en.wikipedia.org/wiki/Closure_(computer_science)#Closure_leaving
ps = ProcString.new "do\n return false\n end"
@l = ps.to_lambda
def self.lambda? # Added "self." for Ruby 1.8
  @l.call
  return true
end
[@l.call, lambda?]
#=> [false, true]

## should dump and load
@test = "do\n false\n end"
@file = "ps_test"
@lines = (23..25)
p1 = ProcString.new @test
p1.file = @file
p1.lines = @lines
str = Marshal.dump(p1)
p2 = Marshal.load str
[p2, p2.file, p2.lines]
#=> [@test, @file, @lines]

