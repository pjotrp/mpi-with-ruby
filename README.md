mpi-with-ruby
=============

Super computing tests using openmpi, Ruby and mpi-ruby.

We have three routines:

1. Reader: read, score and broadcast
2. Responder: responds to the broadcast
3. Receiver: receive and write

The reader reads a file of location quality scores, and broadcasts possible
combinations of SNPs. Multiple readers are running at the same time.

The responder responds to the broadcast when a match exists already.

The receiver catches the responses and writes a new quality score.

The reader and responder share 'memory'. For this
prototype implementation we'll use a simple database. The readers add
(reliable) SNPs to the table, and the responders read them.

First install Tokyo Cabinet DB:

```sh
    apt-get install libtokyocabinet-dev
    gem install tokyocabinet
```

Also install mpi-ruby 

```sh
    apt-get install mpi-default-dev mpi-default-bin
    rvm use 1.8.7
    gem install ruby-mpi
```

Note we use 1.8.7 because the MPI wrappers are not supported on later Rubies.

Next build mpi-ruby - a C wrapper - from https://github.com/abedra/mpi-ruby and execute

```sh
    env LD_LIBRARY_PATH=~/.rvm/rubies/ruby-1.8.7-p352/lib/ mpiexec -np 4 contrib/mpi-ruby/src/mpi_ruby example/basic-test.rb 
        I'm 0 and sending a message to 1
        I'm 2 and sending a message to 3
        I'm 1 and this message came from 0 with tag 0: 'Hello, I'm 0, you must be 1'
        I'm 3 and this message came from 2 with tag 0: 'Hello, I'm 2, you must be 3'
```

Test MPI with Tokyocabinet:

```sh
    env LD_LIBRARY_PATH=~/.rvm/rubies/ruby-1.8.7-p352/lib/ mpiexec -np 4 contrib/mpi-ruby/src/mpi_ruby -I /home/wrk/.rvm/gems/ruby-1.8.7-p352/gems/tokyocabinet-1.29/ example/tokyocabinet-test.rb 
        this-is-3-value
        this-is-0-value
        this-is-2-value
        this-is-1-value
```

At this point everything is in place to test our routines.
