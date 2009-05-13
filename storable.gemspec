@spec = Gem::Specification.new do |s|
	s.name = "storable"
  s.rubyforge_project = "storable"
	s.version = "0.5.3"
	s.summary = "Storable: Marshal Ruby classes into and out of multiple formats (yaml, json, csv, tsv)"
	s.description = s.summary
  s.author = "Delano Mandelbaum"
  s.email = "delano@solutious.com"
  s.homepage = "http://solutious.com/"
  
  
  # = EXECUTABLES =
  # The list of executables in your project (if any). Don't include the path, 
  # just the base filename.
  s.executables = %w[]
  
  # = DEPENDENCIES =
  # Add all gem dependencies
  
  # = MANIFEST =
  # The complete list of files to be included in the release. When GitHub packages your gem, 
  # it doesn't allow you to run any command that accesses the filesystem. You will get an
  # error. You can ask your VCS for the list of versioned files:
  # git ls-files
  # svn list -R
  s.files = %w(
  CHANGES.txt
  LICENSE.txt
  README.rdoc
  Rakefile
  lib/storable.rb
  lib/storable/orderedhash.rb
  storable.gemspec
  )
  
  s.extra_rdoc_files = %w[README.rdoc LICENSE.txt]
  s.has_rdoc = true
  s.rdoc_options = ["--line-numbers", "--title", s.summary, "--main", "README.rdoc"]
  s.require_paths = %w[lib]
  s.rubygems_version = '1.3.0'

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2
 
    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<RedCloth>, [">= 4.0.4"])
    else
      s.add_dependency(%q<RedCloth>, [">= 4.0.4"])
    end
  else
    s.add_dependency(%q<RedCloth>, [">= 4.0.4"])
  end
  
end