# Reader reads data from a file and stores strong SNPs in shared space (Tokyocabinet)
#
# You'll need JSON. Run it with
#
# time env LD_LIBRARY_PATH=~/.rvm/rubies/ruby-1.8.7-p352/lib/ mpiexec -np 4 contrib/mpi-ruby/src/mpi_ruby -I /home/wrk/.rvm/gems/ruby-1.8.7-p352/gems/json-1.7.5/lib/ bin/reader.rb

$: << "./lib"

require "json"
require "parseline"

DO_SPLIT = false
PROB_THRESHOLD = 0.5
MPI_ANY_SOURCE = -1  # from /usr/lib/openmpi/include/mpi.h
MPI_ANY_TAG    = -1  # from /usr/lib/openmpi/include/mpi.h

pid = MPI::Comm::WORLD.rank()   # the rank of the MPI process
num_processes = MPI::Comm::WORLD.size()    # the number of processes

pid = 0 if pid == nil
startwtime = MPI.wtime()

print "Rank #{pid} out of #{num_processes} processes\n"

def broadcast_for_haplotype num_processes, pid, start, list, stop
  # p [start.nuc,list.map { |g| g.nuc }.join,stop.nuc]
  # Turn message into a string (serialize)
  nucs  = [ start.nuc, list.map { |g| g.nuc }, stop.nuc ]
  probs = [ start.prob, list.map { |g| g.prob }, stop.prob ]
  poss  = [ start.pos, list.map { |g| g.pos }, stop.pos ]

  (0..num_processes/2-1).each do | p |
    dest_pid = p + 4 
    if dest_pid != pid
      puts "Sending #{start.pos} from #{pid} to #{dest_pid}"
      # We use a *blocking* send. After completion we can calculate the new probabilities
      # Non-blocking looks interesting, but actually won't help because we are in a lock-step
      # scoring process anyway
      MPI::Comm::WORLD.send([poss,nucs,probs].to_json, dest_pid, pid) 
      # $stderr.print "Waiting for #{dest_pid}"
      msg,status = MPI::Comm::WORLD.recv(dest_pid,pid)
      if msg == "MATCH!"
        # Another haplotype matches our SNPs
        return true
      end
    end
  end
  false
end

# ---- Read ind file
filen="test/data/ind#{pid+1}.tab"
f = File.open(filen)

# Split the genome into smaller sections
def each_genome_section f
  section = []
  ParseLine::tail_each_genotype(f) do | g |
    section << g
    if DO_SPLIT and section.size > 100 and g.prob > PROB_THRESHOLD
      yield section
      section = [section.last]
    end
  end
  yield section
end

# ---- Split genome on high scores, so we get a list of High - low+ - High. Broadcast
#      each such genome - sorry for the iterative approach

outf = File.open("snp#{pid+1}.tab","w")

each_genome_section(f) do | genome_section |
  start = nil
  list  = []
  stop  = nil
  genome_section.each do | g |
    # $stderr.print "." if i % 100 == 0
    next if g.nuc == 'x'  # note that not all nuc positions will be added
    if g.prob > PROB_THRESHOLD
      # High prob SNP
      if start and list.size > 0
        # We have a list of SNPs!
        stop = g
        result = broadcast_for_haplotype(num_processes,pid,start,list,stop) if list.size < 4  # ignore highly variable regions
        # write SNPs to output file
        outf.print start.pos,"\t",start.nuc,"\n"
        if result == true
          list.each do | g |
            outf.print g.pos,"\t",g.nuc,"\n"
          end
        end
        # restart search from the next probable SNP
        start = stop
        list = []
        stop = nil
      else
        start = g
      end
    else
      # Low prob SNP
      if start
        list << g
      end
    end
  end
end

sleep 1 # wait for queue purge and stop responders

MPI::Comm::WORLD.send("QUIT", pid+4, pid) 

endwtime = MPI.wtime()
$stderr.print "\nwallclock time of #{pid} = #{endwtime-startwtime}\n"


