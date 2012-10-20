$: << './lib'

require "json"
require "parseline"

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
print "Rank #{pid} out of #{num_processes} processes (responder #{filen})\n"
genome = []
f = File.open(filen)
$genome = []  # global cache

# The responder acts 'independently', receiving messages and responding to queries
def handle_responder pid,f,individual
  have_message,req = MPI::Comm::WORLD.iprobe(MPI_ANY_SOURCE, MPI_ANY_TAG)
  if have_message
    msg,status = MPI::Comm::WORLD.recv(MPI_ANY_SOURCE, MPI_ANY_TAG)
    source_pid = status.source
    tag = status.tag
    # $stderr.print msg
    if msg == "QUIT"
      $stderr.print "\nExiting #{pid}"
      exit 0
    else
      # unpack info
      positions, list1, probs = JSON.parse(msg)
      start_pos, list_pos, end_pos = positions
      start, list, stop = list1
      start_prob, list_prob, end_prob = probs
      # Do we have matching sequence?
      # First make sure the reader has gotten to this point... FIXME - this stops all
      if end_pos > $genome.size-1
        ParseLine::tail_each_genotype(f) do | g |
          $genome << g
          break if DO_SPLIT and end_pos <= $genome.size-1
        end
      end
      seq = $genome[start_pos..end_pos]
      # p [ seq.map{ |g| g.nuc }, start, stop ]
      if seq.first.nuc == start and seq.last.nuc == stop and seq.first.prob > PROB_THRESHOLD and seq.last.prob > PROB_THRESHOLD
        $stderr.print "\nWe may have a match for #{source_pid} from #{pid}!"
        $stderr.print "\nResponding to #{source_pid} (tag #{individual})"
        middle_seq = seq[1..-2]
        middle_seq.each_with_index do | g, i |
          if g.nuc != list[i] or g.prob < PROB_THRESHOLD
            # $stderr.print "\nWe have NO match!"
            MPI::Comm::WORLD.send("NOMATCH!", source_pid, tag) 
            return
          end
        end
        $stderr.print "\nWe have a match!"
        MPI::Comm::WORLD.send("MATCH!", source_pid, tag) 
        return
      end
      # $stderr.print "\nWe have NO match for #{source_pid} from #{pid}!"
      MPI::Comm::WORLD.send("NOMATCH!", source_pid, tag) 
    end
    $stderr.print "^"
  else
    # $stderr.print "W"
    # sleep 0.01
  end
end

while true
  handle_responder(pid,f,individual)
end

