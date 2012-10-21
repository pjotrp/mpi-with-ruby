mpi-with-ruby
=============

# Introduction

Super computing tests using openmpi, Ruby and mpi-ruby.

We have three routines:

1. Data generator: Timed generation of data (sambamba simulation)
2. Scorer: read data, score and haplotype broadcast, receive and write
3. Responder: read data, score strong SNPs only, and respond to haplotype broadcast

Serial explanation:

The reader reads a file of location quality scores, and broadcasts possible
combinations of SNPs.

The haplotype responder responds to the broadcast when a match exists.

The receiver catches the responses and writes a new quality score.

Basically the reader scores SNPs for one individual. The Responder
responds to queries by other individuals.

The scorer and responder share 'memory' - that is the data file.  The
table is a simple (growing) file.

# TODO

* Do not respond to all messages (done)
* Read files on the fly (done)
* Use Kernel::select for readers (done)
* Add regression tests (done)
* Correct MPI finalize handling (done)
* Check for sambamba to write file on the fly (done)
* Test MPI performance on single machine (done)
* Simulate SNP distances (in progress)
* Scoring in the haplotype responder
* Use sambamba with MPI on cluster
* Test MPI performance on cluster
* Measure and speed up textual (un)marshalling, probably a bottle neck (currently using JSON)
* If MPI itself is a bottle neck, combine messages into larger messages

# mpi-ruby bug(s)

I found is that mpi-ruby contains a nasty bug. The MPI
send command does not initialize the buffer size. Another catch is
that the number of MPI messages is double that what it should be - as
the (uninitialized!) buffer size is sent as message separately. On a
local machine this gives an advantage, but on a network it may not.

# Performance

Current performance based on 1000 SNPs (on a single 4 core box):

* 4 cores,  4 individuals ~ wallclock time 0.35s
* 4 cores,  8 individuals ~ wallclock time 1.10s
* 4 cores, 16 individuals ~ wallclock time 3.46s

removing MPI::iprobe gains time

* 4 cores,  2 individuals ~ wallclock time 0.08s
* 4 cores,  4 individuals ~ wallclock time 0.23s
* 4 cores,  8 individuals ~ wallclock time 1.07s
* 4 cores, 16 individuals ~ wallclock time 3.11s

fixing the mpi-ruby send buffer bug and moving the default receive buffer on
the stack

* 4 cores,  2 individuals ~ wallclock time 0.03s
* 4 cores,  4 individuals ~ wallclock time 0.10s
* 4 cores,  8 individuals ~ wallclock time 0.41s
* 4 cores, 16 individuals ~ wallclock time 1.44s

Other tuning:

* Adding "-mca yield_when_idle 1" slows things down significantly (on a single 4-core Linux 3.2.0 box). Still need to test that on a cluster.
* When moving Kernel::select after an empty f.gets, 10% gets knocked off - that is the default now

# Install

Also install mpi-ruby using Ruby 1.8.7 on [rvm](https://rvm.io/rvm/install/).

```sh
    apt-get install mpi-default-dev mpi-default-bin
    rvm use 1.8.7
    # gem install ruby-mpi <-- actually we don't use this
```

You should be able to do

```sh
    pjotrp@login2:~$ ~/.rvm/rubies/ruby-1.8.7-p371/bin/ruby -v
    ruby 1.8.7 (2012-10-12 patchlevel 371) [x86_64-linux]
```

Note we use 1.8.7 because below MPI wrappers are not supported on later Rubies.

Next build mpi-ruby - a C wrapper - from https://github.com/pjotrp/mpi-ruby.git and execute

```sh
    git clone https://github.com/pjotrp/mpi-ruby.git
    cd mpi-ruby
    module load openmpi/gnu        # on LISA
    module unload compilerwrappers # LISA: otherwise the build system gets confused
```

Modify src/Makefile to contain something like this

```make
Makefile:RUBY_CFLAGS = -I/usr/lib/ruby/1.8/x86_64-linux -I/usr/include -I/home/pjotrp/.rvm/src/ruby-1.8.7-p371
LIBS =  -lruby -L/home/pjotrp/.rvm/rubies/ruby-1.8.7-p371/lib
RUBY_LIBS = -lruby -L/home/pjotrp/.rvm/rubies/ruby-1.8.7-p371/lib
````

```sh
    env LD_LIBRARY_PATH=~/.rvm/rubies/ruby-1.8.7-p371/lib mpiexec -np 4 contrib/mpi-ruby/src/mpi_ruby example/basic-test.rb 
        I'm 0 and sending a message to 1
        I'm 2 and sending a message to 3
        I'm 1 and this message came from 0 with tag 0: 'Hello, I'm 0, you must be 1'
        I'm 3 and this message came from 2 with tag 0: 'Hello, I'm 2, you must be 3'
```

On LISA

```sh
pjotrp@login2:~$ ~/opt/ruby/mpi-with-ruby/test-lisa.sh
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

# Algorithm

## Data generator

The genotypes are generated for 3 individuals by

```sh
    ruby bin/data-generator.rb 3 
```

Every file contains the reference with possible SNPs, the haplotype (4
types by default), followed by the SNP of the individual and a probability:

    ==> ind2.tab <==
    cc      2       c       1.00
    ac      2       a       0.97
    gg      2       g       0.38
    ga      2       a       0.07
    ga      2       g       0.49
    ta      2       t       1.00
    at      2       a       0.56
    ta      2       a       1.00
    tc      2       c       1.00
    ta      2       a       1.00

    ==> ind3.tab <==
    cc      2       c       0.98
    ac      2       a       0.45
    gg      2       g       1.00
    ga      2       a       1.00
    ga      2       g       1.00
    ta      2       t       0.16
    at      2       a       0.59
    ta      2       a       1.00
    tc      2       c       0.27
    ta      2       a       1.00

This section has the same haplotype.
So comparing ind2 with ind3, it is easy to see that the 'c' in the
last 'aca' is probably correct, despite its low probability in ind3.
Also some of the other SNPs may be correct, depending on the scoring
algorithm. Note, we simplify the SNP scoring by using a homozygous
genome. This algorithm is for testing MPI performance only. 

## Reader

Each reader reads one of above ind?.tab files. It broadcasts all
weaker SNPs together with the strong SNPs. I.e. in above example Ind1 
will broadcast

    a       0.97
    g       0.38
    a       0.07
    g       0.49
    t       1.00

and 

    t       1.00
    a       0.56
    a       1.00

and

    a       1.00
    c       0.27
    a       1.00

for others to respond to.

## Responder

The responder for Ind2 should respond to the last broadcast with

    a       1.00
    c       1.00
    a       1.00

## Receiver

The receiver for Ind3 should get the response, and write out the SNP
map for Ind3. In this case

    aa      2       a       1.00
    cc      2       c       1.00
    aa      2       a       1.00

Here we combined the receiver in the reader - this is possible since
we use send and receive pairs, and keep the scoring in lock step.

# Notes

## MPI spinning

Use mpiexec with '-mca yield_when_idle 1'.
  
    echo "1" >/proc/sys/kernel/sched_compat_yield

## Using a DB

At the moment we are following a growing SNP file, as it is generated
by Sambamba.  We may write a version that uses Tokyo Cabinet DB:

```sh
    apt-get install libtokyocabinet-dev
    gem install tokyocabinet
```

Copyright (c) 2012 Pjotr Prins and Artem Tarasov under a BSD license
