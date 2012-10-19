#! /bin/bash

np=$1
if [ -z $np ]; then np=4 ; fi

rvm use 1.8.7
time env LD_LIBRARY_PATH=~/.rvm/rubies/ruby-1.8.7-p352/lib/ mpiexec -np $np contrib/mpi-ruby/src/mpi_ruby example/basic-test.rb 
time env LD_LIBRARY_PATH=~/.rvm/rubies/ruby-1.8.7-p352/lib/ mpiexec -np $np contrib/mpi-ruby/src/mpi_ruby -I /home/wrk/.rvm/gems/ruby-1.8.7-p352/gems/tokyocabinet-1.29/ example/tokyocabinet-test.rb 

# ruby bin/data-generator.rb 16
