
module FileReader

  def FileReader::tail_each_line f
    while true
      s = f.gets 
      if s != nil
        # We got a string of data
        if s.strip == "End"
          yield :eof
          return
        end
        yield s 
      else
        # We are moving too fast
        # $stderr.print "reader pause"
        sleep 0.01
        select([f]) #  <-- use when producer is slower than reader
      end
    end
  end

end
