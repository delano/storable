@spec = Gem::Specification.new do |s|
  s.name = "storable"
  s.version = "0.9-RC2"
  s.summary = "Ruby classes as strings"
  s.description = "Storable: Marshal Ruby classes into and out of multiple formats (yaml, json, csv, tsv)"
  s.authors = ["Delano Mandelbaum"]
  s.email = "gems@solutious.com"
  s.homepage = "https://github.com/delano/storable/"
  s.licenses = ["MIT"]  # https://spdx.org/licenses/MIT-Modern-Variant.html
  s.files = %w(
    README.md
    Rakefile
    bin/example
    bin/tryouts
    lib/core_ext.rb
    lib/proc_source.rb
    lib/storable.rb
    lib/storable/orderedhash.rb
    storable.gemspec
  )
  s.executables = %w(
  )
  s.extra_rdoc_files = %w[README.md]
  s.rdoc_options = ["--line-numbers", "--title", s.summary, "--main", "README.md"]
  s.require_paths = %w[lib]
  s.rubygems_version = '3.2.21'
end
