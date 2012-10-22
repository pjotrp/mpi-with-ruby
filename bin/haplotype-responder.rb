$: << './lib'

require "parseline"

VERBOSE = false
DO_SPLIT = true      # Read input file in split fashion
PROB_THRESHOLD = 0.5
MPI_ANY_SOURCE = -1  # from /usr/lib/openmpi/include/mpi.h
MPI_ANY_TAG    = -1  # from /usr/lib/openmpi/include/mpi.h

pid = MPI::Comm::WORLD.rank()              # the rank of the MPI process
num_processes = MPI::Comm::WORLD.size()    # the number of processes
individuals = num_processes/2

individual = pid+1-individuals             # counting individuals from 1

# ---- Read ind file
filen="test/data/ind#{individual}.tab"
print "Rank #{pid} out of #{num_processes} processes (responder #{filen})\n" if VERBOSE
f = File.open(filen)
$snp_cache = []  # global cache
$quit_messages = [] 

def match seq, list
  result = []
  # We found the overlapping SNP positions in seq. Now assert we have a haplotype
  # and return overlapping SNPs
  # Does seq contain start?
  start = list.first
  start_idx = seq.index { |g| g == start } 
  if start_idx
    # print "\nAnchor start #{start}!"
    stop = list.last
    stop_idx = seq.index { |g| g == stop } 
    if stop_idx
      # print "\nAnchor stop #{stop}!"
      # We have anchors!
      subseq = seq[start_idx+1..stop_idx-1]
      sublist = list[1..-2]
      subseq.each do |h| 
        list.each do |g|
          result << h if h == g and h.prob > PROB_THRESHOLD
        end
      end
    end
  end
  result
end

# The responder acts 'independently', receiving messages and responding to queries
def handle_responder pid,f,individual,individuals
  msg,status = MPI::Comm::WORLD.recv(MPI_ANY_SOURCE, individual)
  source_pid = status.source
  # raise "Problem" if status.tag != individual
  tag = status.tag # i.e. tag = individual
  if msg == "QUIT" 
    $quit_messages << source_pid
    if $quit_messages.size == individuals - 1
      $stderr.print "\nExiting #{pid}" if VERBOSE
      exit 0
    end
  else
    list = GenotypeSerialize::deserialize(msg)
    current_pos = list.first.pos
    end_pos = list.last.pos
    if $snp_cache.size ==0 or end_pos > $snp_cache.last.pos 
      # continue filling the cache, until we have reached the right section
      ParseLine::tail_each_genotype(f) do | g |
        $snp_cache << g
        break if end_pos <= g.pos and !DO_SPLIT
      end
    end
    # find first and last item in cache, starting from the tail
    first = $snp_cache.rindex { |g| g.pos <= current_pos }
    last  = $snp_cache.rindex { |g| g.pos >= end_pos }
    if first==nil or last==nil
      MPI::Comm::WORLD.send("NOMATCH!", source_pid, tag) 
      return
    end
    seq = $snp_cache[first..last]
    result = match(seq,list)
    if result.size > 0
      print "\nWe have a match!" if VERBOSE
      send_msg = GenotypeSerialize::serialize(result)
      MPI::Comm::WORLD.send(send_msg, source_pid, tag) 
    else
      # $stderr.print "\nWe have NO match for #{source_pid} from #{pid}!"
      MPI::Comm::WORLD.send("NOMATCH!", source_pid, tag) 
    end
  end
  $stderr.print "^" if VERBOSE
end

while true
  handle_responder(pid,f,individual,individuals)
end

