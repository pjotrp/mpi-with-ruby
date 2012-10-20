
module FileReader

  def FileReader::tail_each_line f
    while true
      select([f]) 
      s = f.gets 
      if s != nil
        return if s.strip == "End"
        yield s 
      else
        # We are moving too fast
        $stderr.print "reader pause"
        sleep 0.01
      end
    end
  end

end
