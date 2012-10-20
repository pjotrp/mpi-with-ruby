#! /bin/sh

NUM=$1
if [ -z $NUM ]; then
  NUM=4
fi

cp test/regression/input/* test/data

rvm use 1.8.7
time env LD_LIBRARY_PATH=~/.rvm/rubies/ruby-1.8.7-p352/lib/ mpiexec -np $NUM contrib/mpi-ruby/src/mpi_ruby -I /home/wrk/.rvm/gems/ruby-1.8.7-p352/gems/json-1.7.5/lib/ bin/snp-scorer.rb : -np $NUM contrib/mpi-ruby/src/mpi_ruby -I /home/wrk/.rvm/gems/ruby-1.8.7-p352/gems/json-1.7.5/lib/ bin/haplotype-responder.rb 

cp snp*.tab test/regression/data
git status test/
