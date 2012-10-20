# Read a growing file
#

$: << './lib'

require 'parseline'

File.open(ARGV[0]) do | f |
  ParseLine::each_rec(f) do |rec|
    p rec 
  end
end
$stderr.print "Done reading!\n"
