require 'proc_source'


describe ProcString do

  subject { ProcString.new "{ false }" }
  
  it "string should be set" do
    subject.should == "{ false }"
  end
  
  it "#file can be set" do
    subject.file = "test.rb"
    subject.file.should == "test.rb"
  end
  
  it "#lines can be set" do
    subject.lines = 1..10
    subject.lines.should == (1..10)
  end
  
  describe "#to_proc" do
    it "should create a proc" do
      ps = ProcString.new "do\n false\n end"
      ps.to_proc.should be_kind_of(Proc)
    end
    
    it "should connect #file and #lines to the proc" do
      ps = ProcString.new "do\n false\n end"
      ps.file = "to_proc_test"
      ps.lines = (100..102)
      p = ps.to_proc
      p.inspect.should include "to_proc_test"
      p.inspect.should include "100"
    end
    
    it "should fail if #file is set and #lines is a non Range" do
      ps = ProcString.new "do\n false\n end"
      ps.file = "to_proc_test"
      ps.lines = 100
      expect{ ps.to_proc }.to raise_error(RuntimeError)
    end
  end
  
  describe "#to_lambda" do
    it "should create a lambda" do
      ps = ProcString.new "do\n return false\n end"
      @l = ps.to_lambda
      # Test is from: http://en.wikipedia.org/wiki/Closure_(computer_science)#Closure_leaving
      def lambda?
        @l.call
        return true
      end
      @l.call.should == false
      lambda?.should == true
    end
  end
  
  describe "Marshal" do
    it "should dump and load" do
      test = "do\n false\n end"
      file = "ps_test"
      lines = (23..25)
      p1 = ProcString.new test
      p1.file = file
      p1.lines = lines
      str = Marshal.dump(p1)
      p2 = Marshal.load str
      p2.should == test
      p2.file.should == file
      p2.lines.should == lines
    end
  end
end


describe Proc do

  describe "#source" do
  
    def block_method(&block)
      @block = block
    end
    
    it "should handle a simple one line proc with brackets" do
      p = Proc.new { false }
      p.source.split.join(' ').should == "{ false }"
    end
    
    it "should handle a simple multiline proc with brackets" do
      p = Proc.new {
        false
      }
      p.source.split.join(' ').should == "{ false }"
    end
    
    it "should handle a simple one line proc with do/end" do
      p = Proc.new do false end
      p.source.split.join(' ').should == "do false end"
    end
    
    it "should handle a simple multiline proc with do/end" do
      p = Proc.new do
        false
      end
      p.source.split.join(' ').should == "do false end"
    end
    
    it "should handle a more complicated proc with brackets" do
      p = Proc.new {
        print 'hello'
        (1..10).each { |i|
          print i
        }
      }
      p.source.split.join(' ').should == "{ print 'hello' (1..10).each { |i| print i } }"
    end
    
    it "should handle a more complicated proc with do/end" do
      p = Proc.new do
        print 'hello'
        (1..10).each { |i|
          print i
        }
      end
      p.source.split.join(' ').should == "do print 'hello' (1..10).each { |i| print i } end"
    end
    
    it "should handle a {} block passed to a method" do
pending "This currently fails on ruby 1.9. It returns the surrounding block."
      block_method {
        false
      }
#      puts @block.source
      @block.source.split.join(' ').should == "{ false }"
    end
    
    it "should handle a do/end block passed to a method" do
      block_method do
        false
      end
      @block.source.split.join(' ').should == "do false end"
    end
    
    describe "#lines" do
      it "should be correct for one line proc" do
        before = __LINE__
        p = Proc.new { false }
        after = __LINE__
        ps = p.source
        ps.lines.min.should == before + 1
        ps.lines.max.should == after - 1
      end
      
      it "should be correct for multiline proc" do
        before = __LINE__
        p = Proc.new { 
          puts "hello"
          puts "goodbye"
          false 
        }
        after = __LINE__
        ps = p.source
        ps.lines.min.should == before + 1
        ps.lines.max.should == after - 1
      end
    end
    
    describe "#file" do
      it "should be correct" do
        p = Proc.new { false }
        ps = p.source
        ps.file.should == __FILE__
      end
    end
  end
  
  describe "#line" do
    it "should be set after calling source" do
      before = __LINE__
      p = Proc.new { false }
      after = __LINE__
      p.source
      line = p.line.to_i
      line.should > before
      line.should < after
    end
  end  
  
  describe "#file" do
    it "should be set after calling source" do
      p = Proc.new { false }
      p.source
      p.file.should == __FILE__
    end
  end  
  
  describe ".from_string" do
    [
      ["{ 1 }", 1],
      ["do 2 end", 2],
      ["{\n3\n}", 3],
      ["do\n4\nend", 4],
      ["{ if true\n  5\nelse\n  6\nend }", 5],
      ["{ p = proc { 7 }; p.call}", 7],
    ].each do |test|
      it "#{test[0].inspect} => #{test[1]}" do
        Proc.from_string(test[0]).call.should == test[1]
      end
    end
    
    describe "validate arity" do
      it "should handle procs with argument: <none>" do
        p = Proc.new { true }
        Proc.from_string(p.source).arity.should == p.arity
      end
    
      it "should handle procs with argument: ||" do
        p = Proc.new { || true }
        Proc.from_string(p.source).arity.should == p.arity
      end
    
      it "should handle procs with argument: |a|" do
        p = Proc.new { |a| true }
        Proc.from_string(p.source).arity.should == p.arity
      end
        
      it "should handle procs with argument: |a,b|" do
        p = Proc.new { |a,b| true }
        Proc.from_string(p.source).arity.should == p.arity
      end
        
      it "should handle procs with argument: |a,b,c|" do
        p = Proc.new { |a,b,c| true }
        Proc.from_string(p.source).arity.should == p.arity
      end
        
      it "should handle procs with argument: |*a|" do
        p = Proc.new { |*a| true }
        Proc.from_string(p.source).arity.should == p.arity
      end
        
      it "should handle procs with argument: |a,*b|" do
        p = Proc.new { |a,*b| true }
        Proc.from_string(p.source).arity.should == p.arity
      end
    end
    
  end
  
  describe "Marshal" do
    it "should fail if #source is nil" do
      p1 = eval "Proc.new { false }"
      p1.source.should be_nil
      expect{ Marshal.dump p1 }.to raise_error RuntimeError
    end
    
    it "should work with simple proc" do
      p1 = Proc.new do false end
      str = Marshal.dump(p1)
      p2 = Marshal.load str
      p1.source.should == p2.source
      p1.call.should == p2.call
      p1.source_descriptor.should == p2.source_descriptor
    end
    
    it "should work with more complex proc" do
      p1 = Proc.new do |a,b,c,d|
        sum = 0
        (1..10).each do |i|
          sum += a*i + b*i + c*i + d*i
        end
        sum
      end
      p2 = Marshal.load(Marshal.dump(p1))
      p2.source.should == p1.source
      p1.call(2,3,5,7).should == 935
      p2.call(2,3,5,7).should == 935
    end
    
  end
end
