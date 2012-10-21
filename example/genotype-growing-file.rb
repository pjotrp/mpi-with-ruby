# Read a growing file
#

$: << './lib'

require 'parseline'

File.open(ARGV[0]) do | f |
  ParseLine::tail_each_genotype(f) do |g|
    puts g
  end
end
$stderr.print "Done reading!\n"
