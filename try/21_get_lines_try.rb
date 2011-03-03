require 'proc_source'

# NOTE: These tests were converted from the specs in
#       https://github.com/notro/storable
#

@linesfile = "try/data/get_lines"
@procsfile = "try/data/procs.rb"

## Get lines
#describe ".get_lines" do
#  [
#    [1, ["LINE1\n", "LINE2\n", "LINE3\n", "LINE4\n", "LINE5\n", "LINE6\n", "LINE7\n", "LINE8\n", "LINE9\n", "LINE10\n", ]],
#    [9, ["LINE9\n", "LINE10\n", ]],
#    [10, ["LINE10\n", ]],
#    [11, []],
#    [12, nil],
#  ].each do |test|
#  ## start_line=#{test[0]}
#      ProcSource.get_lines("spec/data/get_lines", test[0]).should == test[1]
#  #=> 
##=> nil

## default start_line
#    ProcSource.get_lines("spec/data/get_lines").should == ["LINE1\n", "LINE2\n", "LINE3\n", "LINE4\n", "LINE5\n", "LINE6\n", "LINE7\n", "LINE8\n", "LINE9\n", "LINE10\n", ]
##=> nil


## should return nil if file doesn't exist
ProcSource.find("spec/data/file_dont_exist")
#=> nil
  
## should return nil if no lines
ProcSource.find(@datafile, 12)
#=> nil
  
## should return only block as default
ProcSource.find(@procsfile)
#=> "{ false }\n"
  
## block_only=false should return the whole line
ProcSource.find(@procsfile, 2, false)
#=> "p = Proc.new { true }\n"
  
## block_only=false should return the whole expression
    ProcSource.find("spec/data/procs.rb", 3, false)
##=> "p = Proc.new { true }\n"
