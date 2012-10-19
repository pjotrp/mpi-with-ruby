#! /bin/sh

rm -v test/data/ind*.tab
ruby ./bin/simulate-data.rb 16 &
# tail -f test/data/ind1.tab
sleep 2
ruby example/read-growing-file.rb test/data/ind1.tab 

