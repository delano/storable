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


describe ProcSource do

  describe ".get_lines" do
    [
      [1, ["LINE1\n", "LINE2\n", "LINE3\n", "LINE4\n", "LINE5\n", "LINE6\n", "LINE7\n", "LINE8\n", "LINE9\n", "LINE10\n", ]],
      [9, ["LINE9\n", "LINE10\n", ]],
      [10, ["LINE10\n", ]],
      [11, []],
      [12, nil],
    ].each do |test|
      it "start_line=#{test[0]}" do
        ProcSource.get_lines("spec/data/get_lines", test[0]).should == test[1]
      end
    end
    
    it "default start_line" do
      ProcSource.get_lines("spec/data/get_lines").should == ["LINE1\n", "LINE2\n", "LINE3\n", "LINE4\n", "LINE5\n", "LINE6\n", "LINE7\n", "LINE8\n", "LINE9\n", "LINE10\n", ]
    end
  end
  
  describe ".find" do
    it "should return nil if file doesn't exist" do
      ProcSource.find("spec/data/file_dont_exist").should == nil
    end
    
    it "should return nil if no lines" do
      ProcSource.find("spec/data/get_lines", 12).should == nil
    end
    
    it "should return only block as default" do
      ProcSource.find("spec/data/procs.rb").should == "{ false }\n"
    end
    
    it "block_only=false should return the whole line" do
      ProcSource.find("spec/data/procs.rb", 2, false).should == "p = Proc.new { true }\n"
    end
    
#    it "block_only=false should return the whole expression" do
#      ProcSource.find("spec/data/procs.rb", 3, false).should == "p = Proc.new { true }\n"
#    end
    
  end
end


describe Proc do

  describe "#source" do
  
    def block_method(&block)
      @block = block
    end
    
    it "should handle a simple one line proc with brackets" do
      p = Proc.new { false }
      p.source.gsub(/ +/, " ").strip.should == "{ false }"
    end
    
    it "should handle a simple multiline proc with brackets" do
      p = Proc.new {
        false
      }
      p.source.gsub(/ +/, " ").strip.should == "{\n false\n }"
    end
    
    it "should handle a simple one line proc with do/end" do
      p = Proc.new do false end
      p.source.gsub(/ +/, " ").strip.should == "do false end"
    end
    
    it "should handle a simple multiline proc with do/end" do
      p = Proc.new do
        false
      end
      p.source.gsub(/ +/, " ").strip.should == "do\n false\n end"
    end
    
    it "should handle a more complicated proc with brackets" do
      p = Proc.new {
        print 'hello'
        (1..10).each { |i|
          print i
        }
      }
      p.source.gsub(/ +/, " ").strip.should == "{\n print 'hello'\n (1..10).each { |i|\n print i\n }\n }"
    end
    
    it "should handle a more complicated proc with do/end" do
      p = Proc.new do
        print 'hello'
        (1..10).each { |i|
          print i
        }
      end
      p.source.gsub(/ +/, " ").strip.should == "do\n print 'hello'\n (1..10).each { |i|\n print i\n }\n end"
    end
    
    it "should handle a {} block passed to a method" do
      block_method {
        false
      }
      @block.source.gsub(/ +/, " ").strip.should == "{\n false\n }"
    end
    
    it "should handle a do/end block passed to a method" do
      block_method do
        false
      end
      @block.source.gsub(/ +/, " ").strip.should == "do\n false\n end"
    end
    
    it "should handle hash assignment {:a=>1} in code with do/end singleline block" do
      p = Proc.new do hash = {:a=>1} end
      p.source.gsub(/ +/, " ").strip.should == "do hash = {:a=>1} end"
    end
    
    it "should handle hash assignment {:a=>1} in code with {} singleline block" do
      p = Proc.new { hash = {:a=>1} }
      p.source.gsub(/ +/, " ").strip.should == "{ hash = {:a=>1} }"
    end
    
    it "should handle hash assignment {:a=>1} in code with do/end multiline block" do
      p = Proc.new do
        hash = {:a=>1}
      end
      p.source.gsub(/ +/, " ").strip.should == "do\n hash = {:a=>1}\n end"
    end
    
    it "should handle hash assignment {:a=>1} in code with {} multiline block" do
      p = Proc.new {
        hash = {:a=>1}
      }
      p.source.gsub(/ +/, " ").strip.should == "{\n hash = {:a=>1}\n }"
    end
    
    it "should handle comments in proc" do
      p = Proc.new { 
        # comment
        true # comment
        # comment
      }
      p.source.gsub(/ +/, " ").strip.should == "{ \n # comment\n true # comment\n # comment\n }"
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
    it "should return correct line" do
      line = __LINE__ + 1
      p = Proc.new { false }
      p.line.should == line
    end
  end  
  
  describe "#file" do
    it "should return correct filename" do
      p = Proc.new { false }
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
  
  describe "JSON" do
    it "should fail if #source is nil" do
      p1 = eval "Proc.new { false }"
      p1.source.should be_nil
      expect{ p1.to_json }.to raise_error RuntimeError
    end
    
    it "should work with simple proc" do
      l1 = __LINE__ + 1
      p1 = Proc.new do false end
      p1_j = JSON.generate p1
      p1_j.should =~ /do false end.*#{__FILE__}.*#{l1},#{l1}/m
      p2 = JSON.parse p1.to_json
      p2.inspect.should =~ /#{__FILE__}:#{l1}/m
      p1.call.should == false
      p2.call.should == false
    end
    
    it "should work with more complex proc" do
      l1 = __LINE__ + 1
      p1 = Proc.new do |a,b,c,d|
        sum = 0
        (1..10).each do |i|
          sum += a*i + b*i + c*i + d*i
        end
        sum
      end
      l2 = __LINE__ - 1
      p1_j = JSON.generate p1
      p1_j.should =~ /sum = 0.*#{__FILE__}.*#{l1},#{l2}/m
      p2 = JSON.parse p1.to_json
      p2.inspect.should =~ /#{__FILE__}:#{l1}/m
      p2.source.should == p1.source
      p1.call(2,3,5,7).should == 935
      p2.call(2,3,5,7).should == 935
    end
    
  end
end
