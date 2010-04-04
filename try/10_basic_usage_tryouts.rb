library :storable, 'lib'

tryouts "Basic Usage" do
  setup do
    class A < Storable
      field :one => String
      field :two => Integer
      field :three => TrueClass
    end
  end

  dream ["string", 1, true]
  drill "Create an object" do
    a = A.new( "string", 1, true)
    [a.one, a.two, a.three]
  end
  
end

