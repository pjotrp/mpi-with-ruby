# Generate input file - and you can set the speed the file gets written

TIME_PER_LINE=0.0001
SIZE=10_000          
HAPLOTYPES = 4 
MUTATION_RATE = 200  # 1 in 200
NUCLEOTIDES = "a g c t".split

individuals = ARGV[0].to_i
time_per_line = TIME_PER_LINE
if ARGV.size == 2
  time_per_line = ARGV[1].to_f
end

snploc = []
reference = []

pos =0
(0..SIZE-1).each do | i |
  pos += rand(100)  # assume SNPs are 100bp apart, it does not really matter
  snploc << pos
  reference <<  [NUCLEOTIDES[rand(4)],NUCLEOTIDES[rand(4)]]
end

# basically the reference is a list of known SNPs
# We simulate haplotypes by combining 'known SNPs'

haplotypes = []
(0..HAPLOTYPES-1).each do | h |
  haplotypes[h] = []
  (0..SIZE-1).each do | j |
    if rand(MUTATION_RATE) == 1
      haplotypes[h] << 'x'
    else
      haplotypes[h] << reference[j][rand(2)]
    end
  end
end

Dir.mkdir("test/data") if !File.exist?("test/data")

f = []
h = []
(0..individuals-1).each do | i |
  fn = "./test/data/ind#{i+1}.tab"
  print "\nWriting #{fn}..."
  f[i] = File.open(fn,"w")
  h[i] = rand(HAPLOTYPES)          # start with any haplotype
end

(0..SIZE-1).each do | j |
  (0..individuals-1).each do | i |
    # SNPs are on average 100bps apart (distance does not really matter here)
    f1 = f[i]
    if rand(300) == 100          # switch haplotype on average every 300 SNP positions
      h[i] = rand(HAPLOTYPES)      
    end
    h1 = h[i]
    # Calculate a probability for the nucleotide, as provided by a sequencer
    prob = rand * 2 
    prob = 1.0 if prob > 1

    f1.printf "%i\t%i\t%s\t%i\t%s\t%.2f\n",j,snploc[j],reference[j].join,h[i],haplotypes[h1][j],prob
    f1.flush  # flush to test growing files
  end
  sleep time_per_line
  print "." if j % 200 == 0
end
(0..individuals-1).each do | i |
  f[i].print "End\n"
end
print "\nDone\n"
