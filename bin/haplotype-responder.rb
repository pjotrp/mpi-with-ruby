$: << './lib'

require "json"
require "parseline"

PROB_THRESHOLD = 0.5
MPI_ANY_SOURCE = -1  # from /usr/lib/openmpi/include/mpi.h
MPI_ANY_TAG    = -1  # from /usr/lib/openmpi/include/mpi.h

pid = MPI::Comm::WORLD.rank()   # the rank of the MPI process
num_processes = MPI::Comm::WORLD.size()    # the number of processes

print "Rank #{pid} out of #{num_processes} processes (responder)\n"

individual = pid - 4

# ---- Read ind file
filen="test/data/ind#{pid+1}.tab"
genome = []
f = File.open(filen)
ParseLine::tail_each_genotype(f) do | g |
  genome << g
end


# The responder acts 'independently', receiving messages and responding to queries
def handle_responder pid, genome
  have_message,req = MPI::Comm::WORLD.iprobe(MPI_ANY_SOURCE, MPI_ANY_TAG)
  if have_message
    msg,status = MPI::Comm::WORLD.recv(MPI_ANY_SOURCE,MPI_ANY_TAG)
    source_pid = status.source
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
      seq = genome[start_pos..end_pos]
      # p [ seq.map{ |g| g.nuc }, start, stop ]
      if seq.first.nuc == start and seq.last.nuc == stop and seq.first.prob > PROB_THRESHOLD and seq.last.prob > PROB_THRESHOLD
        $stderr.print "\nWe may have a match for #{source_pid} from #{pid}!"
        middle_seq = seq[1..-2]
        middle_seq.each_with_index do | g, i |
          if g.nuc != list[i] or g.prob < PROB_THRESHOLD
            # $stderr.print "\nWe have NO match!"
            MPI::Comm::WORLD.send("NOMATCH!", source_pid, source_pid) 
            return
          end
        end
        $stderr.print "\nWe have a match!"
        MPI::Comm::WORLD.send("MATCH!", source_pid, source_pid) 
        return
      end
      # $stderr.print "\nWe have NO match for #{source_pid} from #{pid}!"
      MPI::Comm::WORLD.send("NOMATCH!", source_pid, source_pid) 
    end
    $stderr.print "^"
  else
    # $stderr.print "W"
    # sleep 0.01
  end
end

while true
  handle_responder(pid,genome)
end

