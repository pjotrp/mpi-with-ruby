# Reader reads data from a file and stores strong SNPs in shared space (Tokyocabinet)
#
# You'll need JSON. Run it with
#
# time env LD_LIBRARY_PATH=~/.rvm/rubies/ruby-1.8.7-p352/lib/ mpiexec -np 4 contrib/mpi-ruby/src/mpi_ruby -I /home/wrk/.rvm/gems/ruby-1.8.7-p352/gems/json-1.7.5/lib/ bin/reader.rb

$: << "./lib"

require "json"
require "parseline"
require "genome_section"

VERBOSE = false
DO_SPLIT = true      # split the input file - to start up quicker
SPLIT_SIZE = 300
PROB_THRESHOLD = 0.5
MIN_MESSAGE_SIZE = 0 # set to 0 for all messages
MPI_ANY_SOURCE = -1  # from /usr/lib/openmpi/include/mpi.h
MPI_ANY_TAG    = -1  # from /usr/lib/openmpi/include/mpi.h

$message_count = 0
$match_count = 0

pid = MPI::Comm::WORLD.rank()   # the rank of the MPI process
num_processes = MPI::Comm::WORLD.size()    # the number of processes
individuals = num_processes/2
individual = pid+1

pid = 0 if pid == nil
startwtime = MPI.wtime()

filen="test/data/ind#{individual}.tab"
print "Rank #{pid} out of #{num_processes} processes (#{filen})\n" if VERBOSE

# Destination haplotype responders - we randomize the list not to hit the same
# nodes at once
$destinations = (0..individuals-1).to_a.sort{ rand() - 0.5 } - [pid]

# We broadcast for a range of matching SNPs. The start genotype and the stop genotype
# are the first and last SNPs. middle contains the ones in the middle.
#
def broadcast_for_haplotype num_processes, pid, individuals, individual, start, middle, stop
  # Prepare turning message into a string (serialize, here we use JSON)
  # idxs  = [ start.idx, middle.map { |g| g.idx }, stop.idx ]  # cheating a bit for now
  poss  = [ start.pos, middle.map { |g| g.pos }, stop.pos ]
  nucs  = [ start.nuc, middle.map { |g| g.nuc }, stop.nuc ]
  probs = [ start.prob, middle.map { |g| g.prob }, stop.prob ]

  result = []
  $destinations.each do | p |
    dest_pid = p + individuals
    dest_individual = p + 1
    puts "Sending idx #{start.idx} from #{pid} to #{dest_pid} (tag #{dest_individual})" if VERBOSE
    # We use a *blocking* send. After completion we can calculate the new probabilities
    # Non-blocking looks interesting, but actually won't help because we are in a lock-step
    # scoring process anyway
    message = [poss,nucs,probs].to_json
    if num_processes > 1
      MPI::Comm::WORLD.send(message, dest_pid, dest_individual) 
      puts "Waiting pid #{pid} for #{dest_pid} (tag #{dest_individual})" if VERBOSE
      msg,status = MPI::Comm::WORLD.recv(dest_pid, dest_individual)
      puts "Received by pid #{pid} from #{dest_pid} (tag #{dest_individual})" if VERBOSE
    end
    if msg == "MATCH!"
      # Another haplotype matches our SNPs
      $match_count += 1
      result << middle
    end
  end
  if result.size > 0
    middle
  else 
    []
  end
end

# ---- Read ind file
f = File.open(filen)

# ---- Split genome on high scores, so we get a list of High - low+ - High. Broadcast
#      each such genome - sorry for the iterative approach

outf = File.open("snp#{pid+1}.tab","w")

GenomeSection::each(f,DO_SPLIT,SPLIT_SIZE,PROB_THRESHOLD) do | genome_section |
  start = nil
  list  = []
  stop  = nil
  genome_section.each do | g |
    break if g == :eof
    next if g.nuc == 'x'  # note that not all nuc positions will be added
    if g.prob > PROB_THRESHOLD
      # High prob SNP, so we can send out a broadcast
      stop = g
      if start and list.size > 0 
        # We have a list of SNPs!
        p [ pid, start.pos, start.info,list.map { |g| g.info },stop.info ]
        list2 = broadcast_for_haplotype(num_processes,pid,individuals,individual,start,list,stop)
        $message_count += 1
        # write SNPs to output file
        outf.print start.pos,"\t",start.nuc,"\t",start.prob,"\tA\n"
        list2.each do | g |
          outf.print g.pos,"\t",g.nuc,"\t",g.prob,"\t!\n"
        end
        # Don't write stop - it is the next start
        # restart search from the next probable SNP
        start = stop
        list = []
        stop = nil
      else
        start = stop
        list = []
      end
    else
      list << g 
    end
  end
end

endwtime = MPI.wtime()
$stderr.print "\n#{$message_count} messages; #{$match_count} matches; wallclock time of #{pid} = #{endwtime-startwtime}\n"

$destinations.each do | p |
  dest_pid = p + individuals
  dest_individual = p + 1
  if num_processes > 1
    $stderr.print "\nSending QUIT from #{pid} to #{dest_pid}" if VERBOSE
    MPI::Comm::WORLD.send("QUIT", dest_pid, dest_individual) 
  end
end


