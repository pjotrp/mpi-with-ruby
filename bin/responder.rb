require "json"

PROB_THRESHOLD = 0.5
MPI_ANY_SOURCE = -1  # from /usr/lib/openmpi/include/mpi.h
MPI_ANY_TAG    = -1  # from /usr/lib/openmpi/include/mpi.h

process_rank = MPI::Comm::WORLD.rank()   # the rank of the MPI process
num_processes = MPI::Comm::WORLD.size()    # the number of processes

# The responder acts 'independently', receiving messages and responding to queries
def handle_responder process_rank, genome
  # have_message,req = MPI::Comm::WORLD.iprobe(MPI_ANY_SOURCE, MPI_ANY_TAG)
  msg = MPI::Comm::WORLD.recv(-1,-1)
  print "^"
end

while true
  handle_responder(process_rank,nil)
end
