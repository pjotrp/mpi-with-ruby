# Reader reads data from a file and stores strong SNPs in shared space (Tokyocabinet)
#
# You'll need JSON. Run it with
#
# time env LD_LIBRARY_PATH=~/.rvm/rubies/ruby-1.8.7-p352/lib/ mpiexec -np 4 contrib/mpi-ruby/src/mpi_ruby -I /home/wrk/.rvm/gems/ruby-1.8.7-p352/gems/json-1.7.5/lib/ bin/reader.rb

require "json"

PROB_THRESHOLD = 0.5
MPI_ANY_SOURCE = -1  # from /usr/lib/openmpi/include/mpi.h
MPI_ANY_TAG    = -1  # from /usr/lib/openmpi/include/mpi.h

process_rank = MPI::Comm::WORLD.rank()   # the rank of the MPI process
num_processes = MPI::Comm::WORLD.size()    # the number of processes

process_rank = 0 if process_rank == nil
startwtime = MPI.wtime()

print "Rank #{process_rank} out of #{num_processes} processes\n"

class Genotype
  attr_reader :pos, :nuc, :prob
  def initialize pos, nuc, prob
    @pos = pos ; @nuc = nuc ; @prob = prob
  end
end

def broadcast num_processes, process_rank, start, list, stop
  # p [start.nuc,list.map { |g| g.nuc }.join,stop.nuc]
  # Turn message into a string (serialize)
  nucs  = [ start.nuc, list.map { |g| g.nuc }, stop.nuc ]
  probs = [ start.prob, list.map { |g| g.prob }, stop.prob ]
  poss  = [ start.pos, list.map { |g| g.pos }, stop.pos ]

  # MPI::Comm::WORLD.bcast([poss,nucs,probs].to_json, process_rank)
  (0..num_processes/2-1).each do | p |
    pnum = p + 4 
    if pnum != process_rank
      puts "Sending #{start.pos} from #{process_rank} to #{pnum}"
      # We use a *blocking* send. After completion we can calculate the new probabilities
      # Non-blocking looks interesting, but actually won't help because we are in a lock-step
      # scoring process anyway
      MPI::Comm::WORLD.send([poss,nucs,probs].to_json, pnum, process_rank) 
      sleep 0.002  # some expensive statistic
    end
  end
end

# ---- Read ind file
filen="test/data/ind#{process_rank+1}.tab"
genome = []
pos = 0
File.open(filen).each_line do | line |
  fields = line.split(/\t/)
  nucleotide = fields[2]
  prob = fields[3].to_f
  g = Genotype.new(pos, fields[2], fields[3].to_f)
  genome << g
  pos += 1
end

# ---- Split genome on high scores, so we get a list of High - low+ - High. Broadcast
#      each such genome - sorry for the iterative approach

start = nil
list  = []
stop  = nil
genome.each_with_index do | g, i |
  $stderr.print "." if i % 100 == 0
  next if g.nuc == 'x'  # note that not all nuc positions will be added
  if g.prob > PROB_THRESHOLD
    # High prob SNP
    if start and list.size > 0
      # We have a list of SNPs!
      stop = g
      broadcast(num_processes,process_rank,start,list,stop) if list.size < 4  # ignore highly variable regions
      # restart search
      stop = start
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
  # Here we process the 'responder' in a separate 'thread'
  # handle_responder(process_rank,genome)
end

sleep 2 # wait for queue purge and stop responders

MPI::Comm::WORLD.send("QUIT", process_rank+4, process_rank) 

endwtime = MPI.wtime()
$stderr.print "\nwallclock time of #{process_rank} = #{endwtime-startwtime}\n"


