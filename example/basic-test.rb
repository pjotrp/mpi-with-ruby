# basic.rb - a simple MPI test, adapted from the mpi_ruby project
#
# All even numbered processes send a message to their rank+1 counterpart
#
# Run this with something like
#
# env LD_LIBRARY_PATH=~/.rvm/rubies/ruby-1.8.7-p352/lib/ mpiexec -np 15 ~/tmp/mpi-ruby/src/mpi_ruby basic.rb

myrank = MPI::Comm::WORLD.rank()   # the rank of the MPI process
csize = MPI::Comm::WORLD.size()    # the number of processes

if myrank % 2 == 0 then
  # All even numbered processes send a message
	if myrank + 1 != csize then
	  puts "I'm #{myrank} and sending a message to #{myrank+1}"
		hello = "Hello, I'm #{myrank}, you must be #{myrank+1}"
		MPI::Comm::WORLD.send(hello, myrank + 1, 0)
	end
else
  # All odd numbered processed receive a message, and display to STDOUT
	msg, status = MPI::Comm::WORLD.recv(myrank - 1, 0)
	puts "I'm #{myrank} and this message came from #{status.source} with tag #{status.tag}: '#{msg}'"
end
