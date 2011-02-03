require 'proc_source'


describe ProcString do

  subject { ProcString.new "{ false }" }
  
  it { should == "{ false }" }
  
  it "sets #file" do
    subject.file = "test.rb"
    subject.file.should == "test.rb"
  end
  
  it "sets #lines" do
    subject.lines = 1..10
    subject.lines.should == (1..10)
  end
  
  it "sets #arity" do
    subject.arity = 1
    subject.arity.should == 1
  end
  
  it "sets #kind" do
    subject.kind = Proc
    subject.kind.should == Proc
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
  
  
end
