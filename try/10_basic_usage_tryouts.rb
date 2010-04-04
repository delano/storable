library :storable, 'lib'

tryouts "Basic Usage" do
  setup do
    class A < Storable
      field :one => String
      field :two => Integer
      field :three => TrueClass
    end
    class B < Storable
      field :one => String
      field :two 
      field :three => TrueClass
    end
  end

  dream ["string", 1, true]
  drill "Storable objects have a default initialize method" do
    a = A.new "string", 1, true
    [a.one, a.two, a.three]
  end
  
  dream ["string", 1, true]
  drill "Field types are optional" do
    b = B.new "string", 1, true 
    txt = b.to_json
    B.from_json txt
    [b.one, b.two, b.three]
  end
  
end

