
module FileReader

  def FileReader::tail_each_line f
    while true
      select([f]) #  <-- use when producer is slower than reader
      s = f.gets 
      if s != nil
        if s.strip == "End"
          yield :eof
          return
        end
        yield s 
      else
        # We are moving too fast
        # $stderr.print "reader pause"
        sleep 0.01
      end
    end
  end

end
