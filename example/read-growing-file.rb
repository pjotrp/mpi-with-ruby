# Read a growing file
#

$: << './lib'

require 'filereader'

File.open(ARGV[0]) do | f |
  FileReader::tail_each_line(f) do |line|
    print line
  end
end
$stderr.print "Done reading!\n"
