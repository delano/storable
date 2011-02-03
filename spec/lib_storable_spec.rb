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


describe Storable do
  describe "10_basic_usage_tryouts" do
    it "Has instance methods" do
      m = A.instance_methods(false).collect(&:to_s).sort
      m.should == ["four", "four=", "one", "one=", "three", "three=", "two", "two="]
    end
    
    it "Storable objects have a default initialize method" do
      a = A.from_array "string", 1, Time.parse("2010-03-04 23:00"), true
      [a.one, a.two, a.three, a.four].should == ["string", 1, Time.parse("2010-03-04 23:00"), true]
    end
    
    it "Supports to_array" do
      a = A.from_array "string", 1, Time.parse("2010-03-04 23:00"), true
      a.to_array.should == ["string", 1, Time.parse("2010-03-04 23:00"), true]
    end
    
    it "Field types are optional" do
      b = B.from_array "string", 1, Time.parse("2010-03-04 23:00") 
      b = B.from_json b.to_json
      [b.one, b.two, b.three].should == ["string", 1, Time.parse("2010-03-04 23:00")]
    end
    
    it "Can restore a proc" do
      calc = Proc.new do
        2+2
      end
      c = C.from_array calc
      c= C.from_json c.to_json
      c.calc.call.should == 4
    end
    
    it "Can specify a sensitive instance" do
      d = D.new
      d.five = 100
      d.sensitive!
      d.sensitive?.should == true
    end
    
    it "Supports sensitive fields" do
      d = D.new
      d.five = 100
      d.sensitive!
      d2 = d.to_hash
      d2[:five].should be_nil
    end
    
    it "Sensitive fields don't appear at as nil in to_array" do
      d = D.new
      d.five = 100
      d.sensitive!
      d.to_array.size.should == 4
    end
    
    it "Supports inheritence" do
      d = D.new
      d.one = 100
      d2 = d.to_hash
      d2[:one].should == 100
    end
  end
end
