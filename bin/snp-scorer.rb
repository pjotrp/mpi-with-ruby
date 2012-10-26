# Reader reads data from a file and stores strong SNPs in shared space (Tokyocabinet)
#
# You'll need JSON. Run it with
#
# time env LD_LIBRARY_PATH=~/.rvm/rubies/ruby-1.8.7-p352/lib/ mpiexec -np 4 contrib/mpi-ruby/src/mpi_ruby -I /home/wrk/.rvm/gems/ruby-1.8.7-p352/gems/json-1.7.5/lib/ bin/reader.rb

$: << "./lib"

# require "json"
require "parseline"
require "genome_section"

if ARGV.size > 0
  basefn=ARGV.shift
  divide=2
  if par=ARGV.shift
    divide = par.to_i
  end
  outfilen=ARGV.shift
end

VERBOSE = false
DO_SPLIT = true      # split the input file - to start up quicker
SPLIT_SIZE = 300
ANCHOR_PROB_THRESHOLD = 0.5
FLOAT_PROB_THRESHOLD  = 0.1
MIN_MESSAGE_SIZE = 0 # set to 0 for all messages
MPI_ANY_SOURCE = -1  # from /usr/lib/openmpi/include/mpi.h
MPI_ANY_TAG    = -1  # from /usr/lib/openmpi/include/mpi.h

$message_count = 0
$match_count = 0
$snp_count = 0

pid = MPI::Comm::WORLD.rank()   # the rank of the MPI process
num_processes = MPI::Comm::WORLD.size()    # the number of processes
individuals = num_processes/2
individual = pid+1

pid = 0 if pid == nil
startwtime = MPI.wtime()

if basefn
  section_size = num_processes/divide
  index = pid % section_size
  filen=File.open(basefn).readlines[index].strip
  filen=ENV["TMPDIR"]+"/"+filen+".snp1" if filen !~ /\.tab$/
end
print "Rank #{pid} out of #{num_processes} processes (#{filen})\n" if VERBOSE

# Destination haplotype responders - we randomize the list not to hit the same
# nodes at once
$destinations = (0..individuals-1).to_a.sort{ rand() - 0.5 } - [pid]

# We broadcast for a range of matching SNPs. The start genotype and the stop genotype
# are the first and last SNPs. middle contains the ones in the middle.
#
def broadcast_for_haplotype num_processes, pid, individuals, individual, start, middle, stop
  send_msg = GenotypeSerialize::serialize([start]+middle+[stop])

  results = []
  $destinations.each do | p |
    dest_pid = p + individuals
    dest_individual = p + 1
    puts "Sending idx #{start.idx} from #{pid} to #{dest_pid} (tag #{dest_individual})" if VERBOSE
    # We use a *blocking* send. After completion we can calculate the new probabilities
    MPI::Comm::WORLD.send(send_msg, dest_pid, dest_individual) 
    puts "Waiting pid #{pid} for #{dest_pid} (tag #{dest_individual})" if VERBOSE
    msg,status = MPI::Comm::WORLD.recv(dest_pid, dest_individual)
    puts "Received by pid #{pid} from #{dest_pid} (tag #{dest_individual})" if VERBOSE
    if msg != "NOMATCH!"
      # print "!",msg
      $match_count += 1
      results << GenotypeSerialize::deserialize(msg)
    end
  end
  # Calculate the new probabilities by combining all results and averaging 
  # haplotype probabilities
  if results.size > 0
    final = {}
    # FIXME count matches on index, and score
    results.each do | result |
      result.each do | h |
        pos = h.pos
        if not final[pos] 
          final[pos] = h.dup
        elsif final[pos].prob < h.prob
          final[pos].set_prob([h.prob,final[pos].prob].max)
        end
      end
    end
    final.sort.map { |k,v| v }  # flatten to array
  else 
    []
  end
end

# ---- Read ind file
f = File.open(filen)

outfilen = "snp#{pid+1}.tab" if not outfilen
outfilen = ENV["TMPDIR"]+'/'+outfilen # always write to scratch
outf = File.open(outfilen,"w")

# ---- Split genome on high scores, so we get a list of High - low+ - High. Broadcast
#      each such genome - sorry for the iterative approach
GenomeSection::each(f,DO_SPLIT,SPLIT_SIZE,ANCHOR_PROB_THRESHOLD) do | genome_section |
  start = nil
  list  = []
  stop  = nil
  genome_section.each do | g |
    next if g.nuc == 'x'  # note that not all nuc positions will be added
    if g.prob > ANCHOR_PROB_THRESHOLD
      # High prob SNP, so we can send out a broadcast
      stop = g
      if start and list.size > 0 
        # We have a list of SNPs!
        # p [ pid, start.pos, start.info,list.map { |g| g.info },stop.info ]
        result = broadcast_for_haplotype(num_processes,pid,individuals,individual,start,list,stop)
        $message_count += 1
        # write SNPs to output file
        outf.print start.pos,"\t",start.nuc,"\t",start.prob,"\tA\n"
        # list.each do | g |
        #   outf.print g.pos,"\t",g.nuc,"\t",g.prob,"\tF\n"
        # end
        result.each do | g |
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
      list << g if g.prob > FLOAT_PROB_THRESHOLD
    end
    $snp_count += 1
  end
end

endwtime = MPI.wtime()
$stderr.print "\n#{$message_count} messages; #{$match_count} matches (#{$match_count*100/$snp_count}%); wallclock time of #{pid} = #{endwtime-startwtime}\n"

$destinations.each do | p |
  dest_pid = p + individuals
  dest_individual = p + 1
  if num_processes > 1
    $stderr.print "\nSending QUIT from #{pid} to #{dest_pid}" if VERBOSE
    MPI::Comm::WORLD.send("QUIT", dest_pid, dest_individual) 
  end
end


