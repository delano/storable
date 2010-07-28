require 'storable'


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


  
## "Storable objects have a default initialize method"
a = A.new "string", 1, Time.parse("2010-03-04 23:00"), true
[a.one, a.two, a.three, a.four]
#=> ["string", 1, Time.parse("2010-03-04 23:00"), true]
  
## "Field types are optional"
b = B.new "string", 1, Time.parse("2010-03-04 23:00") 
b = B.from_json b.to_json
[b.one, b.two, b.three]
#=> ["string", 1, Time.parse("2010-03-04 23:00")]

## "Can restore a proc"
calc = Proc.new do
  2+2
end
c = C.new calc
c= C.from_json c.to_json
c.calc.call
#=> 4
  

