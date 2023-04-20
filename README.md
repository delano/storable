# Storable - v0.9-RC2

Marshal Ruby classes in to and out of multiple formats (yaml, json, csv, tsv).

## Example

    require 'storable'

    class Machine < Storable
      field :environment            # Define field names for Machine. The
      field :role                   # default type is String, but you can
      field :position => Integer    # specify a type using a hash syntax.
    end

    mac1 = Machine.new              # Instances of Machine have accessors
    mac1.environment = "stage"      # just like regular attributes.
    mac1.role = "app"
    mac1.position = 1

    puts "# YAML", mac1.to_yaml     # Note: the field order is maintained
    puts "# CSV", mac1.to_csv       # => stage,app,1
    puts "# JSON", mac1.to_json     # Note: field order not maintained.

    mac2 = Machine.from_yaml(mac1.to_yaml)
    puts mac2.environment           # => "stage"
    puts mac2.position.class        # => Fixnum


## Sensitive Fields

    require 'storable'

    class Calc < Storable
      field :three
      field :two
      field :one
      sensitive_fields :three
    end

    calc = Calc.new 3, 2, 1
    calc.to_a                       # => [3, 2, 1]
    calc.sensitive!
    calc.to_a                       # => [2, 1]


## Storing Procs

Storable can also marshal Proc objects to and from their actual source code.

    require 'storable'

    class Maths < Storable
      field :x         => Float
      field :y         => Float
      field :calculate => Proc
    end

    m1 = Maths.new 2.0, 3.0
    m1.calculate = Proc.new { @x * @y }

    m1.calculate.source            # => "{ @x * @y }"
    m1.call :calculate             # => 6.0

    dump = m1.to_json

    m2 = Maths.from_json dump
    m2.call :calculate             # => 6.0


Anything is possible when you keep your mind open and you use Ruby.


## Installation

Via Rubygems, one of:

    $ sudo gem install storable
    $ sudo gem install delano-storable --source http://gems.github.com/

or via download:
* [storable-latest.tar.gz](http://github.com/delano/storable/tarball/latest)
* [storable-latest.zip](http://github.com/delano/storable/zipball/latest)


## Prerequisites

* Ruby <=2.7, >=1.9, possibly JRuby


## Credits

* Delano Mandelbaum (delano@solutious.com)
* lib/proc_source.rb is based on [imedo/background](http://github.com/imedo/background)
* OrderedHash implementation by Jan Molic


## Thanks

* Pierre Riteau ([priteau](https://github.com/priteau)) for bug fixes.
* [notro](https://github.com/notro) for proc_source improvements.


## More Info

* [GitHub](http://github.com/delano/storable)

## License

See: [storable.gemspec](https://github.com/delano/storable/blob/main/storable.gemspec)
