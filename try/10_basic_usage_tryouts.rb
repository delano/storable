$:.unshift '/Users/delano/Projects/opensource/storable/lib'
load 'storable.rb'

tryouts "Basic Usage", :api do
  setup do
    class A < Storable
      field :one => String
      field :two => Integer
      field :three => Time
      field :four => Boolean
    end
    class B < Storable
      field :one => String
      field :two 
      field :three => Time
    end
    class C < Storable
      field :calc => Proc
    end
  end

  dream ["string", 1, Time.parse("2010-03-04 23:00"), true]
  drill "Storable objects have a default initialize method" do
    a = A.new "string", 1, Time.parse("2010-03-04 23:00"), true
    [a.one, a.two, a.three, a.four]
  end
  
  dream ["string", 1, Time.parse("2010-03-04 23:00")]
  drill "Field types are optional" do
    b = B.new "string", 1, Time.parse("2010-03-04 23:00") 
    b = B.from_json b.to_json
    [b.one, b.two, b.three]
  end
  
  dream 4
  drill "Can restore a proc" do
    calc = Proc.new do
      2+2
    end
    c = C.new calc
    c= C.from_json c.to_json
    c.calc.call
  end
  
end

