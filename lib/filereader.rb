
module FileReader

  def FileReader::tail_each_line f
    sleep_counter = 0
    while true
      s = f.gets 
      if s != nil
        sleep_counter = 0
        s = s.chomp
        # We got a string of data
        break if s == "End"
        yield s 
      else
        # We are moving too fast
        # $stderr.print "reader pause"
        break if sleep_counter > 10
        sleep_counter += 1
        sleep 0.01
        select([f]) #  <-- use when producer is slower than reader
      end
    end
  end

end
