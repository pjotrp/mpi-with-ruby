# Read a growing file
#

File.open(ARGV[0]) do | f |
  while true
    select([f]) 
    s = f.gets 
    if s != nil
      print s 
      break if s.strip == "End"
    end
  end
end
$stderr.print "Done reading!\n"
