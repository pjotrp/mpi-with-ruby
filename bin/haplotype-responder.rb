require "json"

PROB_THRESHOLD = 0.5
MPI_ANY_SOURCE = -1  # from /usr/lib/openmpi/include/mpi.h
MPI_ANY_TAG    = -1  # from /usr/lib/openmpi/include/mpi.h

process_rank = MPI::Comm::WORLD.rank()   # the rank of the MPI process
num_processes = MPI::Comm::WORLD.size()    # the number of processes

class Genotype
  attr_reader :pos, :nuc, :prob
  def initialize pos, nuc, prob
    @pos = pos ; @nuc = nuc ; @prob = prob
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

# The responder acts 'independently', receiving messages and responding to queries
def handle_responder process_rank, genome
  have_message,req = MPI::Comm::WORLD.iprobe(MPI_ANY_SOURCE, MPI_ANY_TAG)
  if have_message
    msg,status = MPI::Comm::WORLD.recv(MPI_ANY_SOURCE,MPI_ANY_TAG)
    pnum = status.source
    # $stderr.print msg
    if msg == "QUIT"
      $stderr.print "\nExiting #{process_rank}"
      exit 0
    else
      # unpack info
      positions, list1, probs = JSON.parse(msg)
      start_pos, list_pos, end_pos = positions
      start, list, stop = list1
      start_prob, list_prob, end_prob = probs
      # Do we have matching sequence?
      seq = genome[start_pos..end_pos]
      p [ seq.map{ |g| g.nuc }, start, stop ]
      if seq.first.nuc == start and seq.last.nuc == stop and seq.first.prob > PROB_THRESHOLD and seq.last.prob > PROB_THRESHOLD
        $stderr.print "\nWe may have a match for #{pnum} from #{process_rank}!"
        middle_seq = seq[1..-2]
        middle_seq.each_with_index do | g, i |
          if g.nuc != list[i] or g.prob < PROB_THRESHOLD
            # $stderr.print "\nWe have NO match!"
            MPI::Comm::WORLD.send("NOMATCH!", pnum, pnum) 
            return
          end
        end
        $stderr.print "\nWe have a match!"
        MPI::Comm::WORLD.send("MATCH!", pnum, pnum) 
        return
      end
      # $stderr.print "\nWe have NO match for #{pnum} from #{process_rank}!"
      MPI::Comm::WORLD.send("NOMATCH!", pnum, pnum) 
    end
    $stderr.print "^"
  end
end

while true
  handle_responder(process_rank,genome)
end

