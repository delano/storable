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
class D < A
  field :five
  sensitive_fields :five
end

  
## "Storable objects have a default initialize method"
a = A.new "string", 1, Time.parse("2010-03-04 23:00"), true
[a.one, a.two, a.three, a.four]
#=> ["string", 1, Time.parse("2010-03-04 23:00"), true]

## Supports to_a
a = A.new "string", 1, Time.parse("2010-03-04 23:00"), true
a.to_a
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
  
## Can specify a sensitive instance
d = D.new
d.five = 100
d.sensitive!
d.sensitive?
#=> true

## Supports sensitive fields
d = D.new
d.five = 100
d.sensitive!
d2 = d.to_hash
d2[:five]
#=> nil

## Sensitive fields don't appear at as nil in to_a
d = D.new
d.five = 100
d.sensitive!
d.to_a.size
## 4

## Supports inheritence
d = D.new
d.one = 100
d2 = d.to_hash
d2[:one]
#=> 100

