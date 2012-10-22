$: << './lib'

require "json"
require "parseline"

VERBOSE = false
DO_SPLIT = true
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

# The responder acts 'independently', receiving messages and responding to queries
def handle_responder pid,f,individual,individuals
  msg,status = MPI::Comm::WORLD.recv(MPI_ANY_SOURCE, individual)
  source_pid = status.source
  tag = status.tag
  if msg == "QUIT" 
    $quit_messages << source_pid
    # $stderr.print "\nReceived QUIT by #{pid} from #{source_pid}"
    if $quit_messages.size == individuals - 1
      $stderr.print "\nExiting #{pid}" if VERBOSE
      exit 0
    end
  else
    # unpack info
    idxs, positions, list1, probs = JSON.parse(msg)
    start_idx, list_idx, end_idx = idxs
    start_pos, list_pos, end_pos = positions
    start, list, stop = list1
    start_prob, list_prob, end_prob = probs
    # Do we have matching sequence?
    # First make sure the reader has gotten to this point... FIXME - this stops all
    if end_idx > $snp_cache.size-1
      ParseLine::tail_each_genotype(f) do | g |
        $snp_cache << g
        break if DO_SPLIT and end_idx <= $snp_cache.size-1
      end
    end
    seq = $snp_cache[start_idx..end_idx]
    if seq.first.nuc == start and seq.last.nuc == stop and seq.first.prob > PROB_THRESHOLD and seq.last.prob > PROB_THRESHOLD
      if VERBOSE
        $stderr.print "\nWe may have a match for #{source_pid} from #{pid}!" 
        $stderr.print "\nResponding to #{source_pid} (tag #{individual})"
      end
      middle_seq = seq[1..-2]
      middle_seq.each_with_index do | g, i |
        if g.nuc != list[i] or g.prob < PROB_THRESHOLD
          # $stderr.print "\nWe have NO match!"
          MPI::Comm::WORLD.send("NOMATCH!", source_pid, tag) 
          return
        end
      end
      print "\nWe have a match!" if VERBOSE
      MPI::Comm::WORLD.send("MATCH!", source_pid, tag) 
      return
    end
    # $stderr.print "\nWe have NO match for #{source_pid} from #{pid}!"
    MPI::Comm::WORLD.send("NOMATCH!", source_pid, tag) 
  end
  $stderr.print "^" if VERBOSE
end

while true
  handle_responder(pid,f,individual,individuals)
end

