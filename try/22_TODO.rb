require 'proc_source'

# NOTE: These tests were converted from the specs in
#       https://github.com/notro/storable
#




describe Proc do

  describe "#source" do
  
    def block_method(&block)
      @block = block
  #=> 
    
  ## should handle a simple one line proc with brackets
      p = Proc.new { false }
      p.source.gsub(/ +/, " ").strip.should == "{ false }"
  #=> 
    
  ## should handle a simple multiline proc with brackets
      p = Proc.new {
        false
      }
      p.source.gsub(/ +/, " ").strip.should == "{\n false\n }"
  #=> 
    
  ## should handle a simple one line proc with do/end
      p = Proc.new do false end
      p.source.gsub(/ +/, " ").strip.should == "do false end"
  #=> 
    
  ## should handle a simple multiline proc with do/end
      p = Proc.new do
        false
    #=> 
      p.source.gsub(/ +/, " ").strip.should == "do\n false\n end"
  #=> 
    
  ## should handle a more complicated proc with brackets
      p = Proc.new {
        print 'hello'
        (1..10).each { |i|
          print i
        }
      }
      p.source.gsub(/ +/, " ").strip.should == "{\n print 'hello'\n (1..10).each { |i|\n print i\n }\n }"
  #=> 
    
  ## should handle a more complicated proc with do/end
      p = Proc.new do
        print 'hello'
        (1..10).each { |i|
          print i
        }
    #=> 
      p.source.gsub(/ +/, " ").strip.should == "do\n print 'hello'\n (1..10).each { |i|\n print i\n }\n end"
  #=> 
    
  ## should handle a {} block passed to a method
      block_method {
        false
      }
      @block.source.gsub(/ +/, " ").strip.should == "{\n false\n }"
  #=> 
    
  ## should handle a do/end block passed to a method
      block_method do
        false
    #=> 
      @block.source.gsub(/ +/, " ").strip.should == "do\n false\n end"
  #=> 
    
  ## should handle hash assignment {:a=>1} in code with do/end singleline block
      p = Proc.new do hash = {:a=>1} end
      p.source.gsub(/ +/, " ").strip.should == "do hash = {:a=>1} end"
  #=> 
    
  ## should handle hash assignment {:a=>1} in code with {} singleline block
      p = Proc.new { hash = {:a=>1} }
      p.source.gsub(/ +/, " ").strip.should == "{ hash = {:a=>1} }"
  #=> 
    
  ## should handle hash assignment {:a=>1} in code with do/end multiline block
      p = Proc.new do
        hash = {:a=>1}
    #=> 
      p.source.gsub(/ +/, " ").strip.should == "do\n hash = {:a=>1}\n end"
  #=> 
    
  ## should handle hash assignment {:a=>1} in code with {} multiline block
      p = Proc.new {
        hash = {:a=>1}
      }
      p.source.gsub(/ +/, " ").strip.should == "{\n hash = {:a=>1}\n }"
  #=> 
    
  ## should handle comments in proc
      p = Proc.new { 
        # comment
        true # comment
        # comment
      }
      p.source.gsub(/ +/, " ").strip.should == "{ \n # comment\n true # comment\n # comment\n }"
  #=> 
    
    describe "#lines" do
    ## should be correct for one line proc
        before = __LINE__
        p = Proc.new { false }
        after = __LINE__
        ps = p.source
        ps.lines.min.should == before + 1
        ps.lines.max.should == after - 1
    #=> 
      
    ## should be correct for multiline proc
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
    #=> 
  #=> 
    
    describe "#file" do
    ## should be correct
        p = Proc.new { false }
        ps = p.source
        ps.file.should == __FILE__
    #=> 
  #=> 
#=> 
  
  describe "#line" do
  ## should return correct line
      line = __LINE__ + 1
      p = Proc.new { false }
      p.line.should == line
  #=> 
#=>   
  
  describe "#file" do
  ## should return correct filename
      p = Proc.new { false }
      p.file.should == __FILE__
  #=> 
#=>   
  
  describe ".from_string" do
    [
      ["{ 1 }", 1],
      ["do 2 end", 2],
      ["{\n3\n}", 3],
      ["do\n4\nend", 4],
      ["{ if true\n  5\nelse\n  6\nend }", 5],
      ["{ p = proc { 7 }; p.call}", 7],
    ].each do |test|
    ## #{test[0].inspect} => #{test[1]}
        Proc.from_string(test[0]).call.should == test[1]
    #=> 
  #=> 
    
    describe "validate arity" do
    ## should handle procs with argument: <none>
        p = Proc.new { true }
        Proc.from_string(p.source).arity.should == p.arity
    #=> 
    
    ## should handle procs with argument: ||
        p = Proc.new { || true }
        Proc.from_string(p.source).arity.should == p.arity
    #=> 
    
    ## should handle procs with argument: |a|
        p = Proc.new { |a| true }
        Proc.from_string(p.source).arity.should == p.arity
    #=> 
        
    ## should handle procs with argument: |a,b|
        p = Proc.new { |a,b| true }
        Proc.from_string(p.source).arity.should == p.arity
    #=> 
        
    ## should handle procs with argument: |a,b,c|
        p = Proc.new { |a,b,c| true }
        Proc.from_string(p.source).arity.should == p.arity
    #=> 
        
    ## should handle procs with argument: |*a|
        p = Proc.new { |*a| true }
        Proc.from_string(p.source).arity.should == p.arity
    #=> 
        
    ## should handle procs with argument: |a,*b|
        p = Proc.new { |a,*b| true }
        Proc.from_string(p.source).arity.should == p.arity
    #=> 
  #=> 
    
#=> 
  
  describe "Marshal" do
  ## should fail if #source is nil
      p1 = eval "Proc.new { false }"
      p1.source.should be_nil
      expect{ Marshal.dump p1 }.to raise_error RuntimeError
  #=> 
    
  ## should work with simple proc
      p1 = Proc.new do false end
      str = Marshal.dump(p1)
      p2 = Marshal.load str
      p1.source.should == p2.source
      p1.call.should == p2.call
      p1.source_descriptor.should == p2.source_descriptor
  #=> 
    
  ## should work with more complex proc
      p1 = Proc.new do |a,b,c,d|
        sum = 0
        (1..10).each do |i|
          sum += a*i + b*i + c*i + d*i
      #=> 
        sum
    #=> 
      p2 = Marshal.load(Marshal.dump(p1))
      p2.source.should == p1.source
      p1.call(2,3,5,7).should == 935
      p2.call(2,3,5,7).should == 935
  #=> 
    
#=> 
  
  describe "JSON" do
  ## should fail if #source is nil
      p1 = eval "Proc.new { false }"
      p1.source.should be_nil
      expect{ p1.to_json }.to raise_error RuntimeError
  #=> 
    
  ## should work with simple proc
      l1 = __LINE__ + 1
      p1 = Proc.new do false end
      p1_j = JSON.generate p1
      p1_j.should =~ /do false end.*#{__FILE__}.*#{l1},#{l1}/m
      p2 = JSON.parse p1.to_json
      p2.inspect.should =~ /#{__FILE__}:#{l1}/m
      p1.call.should == false
      p2.call.should == false
  #=> 
    
  ## should work with more complex proc
      l1 = __LINE__ + 1
      p1 = Proc.new do |a,b,c,d|
        sum = 0
        (1..10).each do |i|
          sum += a*i + b*i + c*i + d*i
      #=> 
        sum
    #=> 
      l2 = __LINE__ - 1
      p1_j = JSON.generate p1
      p1_j.should =~ /sum = 0.*#{__FILE__}.*#{l1},#{l2}/m
      p2 = JSON.parse p1.to_json
      p2.inspect.should =~ /#{__FILE__}:#{l1}/m
      p2.source.should == p1.source
      p1.call(2,3,5,7).should == 935
      p2.call(2,3,5,7).should == 935
  #=> 
    
#=> 
end
