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

* Do not respond to all messages
* Use Kernel::select for readers
* Scoring in the haplotype responder
* Test MPI performance
* Measure and speed up textual (un)marshalling, probably a bottle neck (currently using JSON)

# Install

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

# Algorithm

## Data generator

The genotypes are generated for 3 individuals by

```sh
    ruby bin/data-generator.rb 3 
```

Every file contains the reference with possible SNPs, the haplotype (4
by default), followed by the SNP of the individual and a probability:

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

We may write a version that uses Tokyo Cabinet DB:

```sh
    apt-get install libtokyocabinet-dev
    gem install tokyocabinet
```



Copyright (c) 2012 Pjotr Prins and Artem Tarasov under a BSD license
