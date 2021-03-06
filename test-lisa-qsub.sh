#! /bin/sh

cd ~/opt/ruby/mpi-with-ruby

NUM=$1
if [ -z $NUM ]; then
  NUM=16
else
  shift
fi

cp test/regression/input/* test/data

# rvm use 1.8.7
ruby=/home/pjotrp/opt/ruby/mpi-ruby/src/mpi_ruby
time env LD_LIBRARY_PATH=/home/pjotrp/.rvm/rubies/ruby-1.8.7-p371/lib mpiexec -np $NUM $ruby -I $HOME/.rvm/gems/ruby-1.8.7-p371/gems/json-1.7.5/lib/ bin/snp-scorer.rb : -np $NUM $ruby -I $HOME/.rvm/gems/ruby-1.8.7-p371/gems/json-1.7.5/lib/ bin/haplotype-responder.rb

mkdir -p test/regression/data
cp snp*.tab test/regression/data
git status test/

if [ "$NUM" != "4" ]; then
  echo "The regression data is for 4 cores only (4 haplotypes)!"
fi
