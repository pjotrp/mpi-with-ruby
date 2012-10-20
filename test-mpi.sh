#! /bin/sh

rvm use 1.8.7
time env LD_LIBRARY_PATH=~/.rvm/rubies/ruby-1.8.7-p352/lib/ mpiexec -bynode -np 4 contrib/mpi-ruby/src/mpi_ruby -I /home/wrk/.rvm/gems/ruby-1.8.7-p352/gems/json-1.7.5/lib/ bin/snp-scorer.rb : -np 4 contrib/mpi-ruby/src/mpi_ruby -I /home/wrk/.rvm/gems/ruby-1.8.7-p352/gems/json-1.7.5/lib/ bin/haplotype-responder.rb 
