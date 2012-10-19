require "json"

PROB_THRESHOLD = 0.5
MPI_ANY_SOURCE = -1  # from /usr/lib/openmpi/include/mpi.h
MPI_ANY_TAG    = -1  # from /usr/lib/openmpi/include/mpi.h

process_rank = MPI::Comm::WORLD.rank()   # the rank of the MPI process
num_processes = MPI::Comm::WORLD.size()    # the number of processes

# The responder acts 'independently', receiving messages and responding to queries
def handle_responder process_rank, genome
  have_message,req = MPI::Comm::WORLD.iprobe(MPI_ANY_SOURCE, MPI_ANY_TAG)
  if have_message
    msg,status = MPI::Comm::WORLD.recv(MPI_ANY_SOURCE,MPI_ANY_TAG)
    # $stderr.print msg
    if msg == "QUIT"
      $stderr.print "\nExiting #{process_rank}"
      exit 0
    end
    $stderr.print "^"
  end
end

sleep 0.01 
while true
  handle_responder(process_rank,nil)
end

