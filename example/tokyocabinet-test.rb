require 'tokyocabinet'
include TokyoCabinet

myrank = MPI::Comm::WORLD.rank()   # the rank of the MPI process

hdb = HDB::new
hdb.open("has-db.tch", HDB::OWRITER | HDB::OCREAT)
hdb.put("this-is-#{myrank}-key","this-is-#{myrank}-value")
puts hdb.get("this-is-#{myrank}-key")


