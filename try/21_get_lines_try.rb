require 'proc_source'

# NOTE: These tests were converted from the specs in
#       https://github.com/notro/storable
#

@linesfile = "try/data/get_lines"
@procsfile = "try/data/procs.rb"

## .get_lines with default start_line on testfile should return all lines
    ProcSource.get_lines(@linesfile)
#=> ["LINE1\n", "LINE2\n", "LINE3\n", "LINE4\n", "LINE5\n", "LINE6\n", "LINE7\n", "LINE8\n", "LINE9\n", "LINE10\n", ]

## .get_lines start_line=1 on testfile should return all lines
ProcSource.get_lines(@linesfile, 1)
#=> ["LINE1\n", "LINE2\n", "LINE3\n", "LINE4\n", "LINE5\n", "LINE6\n", "LINE7\n", "LINE8\n", "LINE9\n", "LINE10\n", ]

## .get_lines start_line=9 on testfile should return 2 lines
ProcSource.get_lines(@linesfile, 9)
#=> ["LINE9\n", "LINE10\n", ]

## .get_lines start_line=10 on testfile should return 1 lines
ProcSource.get_lines(@linesfile, 10)
#=> ["LINE10\n", ]

## .get_lines start_line=11 on testfile should return 0 lines
ProcSource.get_lines(@linesfile, 11)
#=> []

## .get_lines start_line=12 on testfile should return nil
ProcSource.get_lines(@linesfile, 12)
#=> nil

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
