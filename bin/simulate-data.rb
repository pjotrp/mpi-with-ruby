# Generate input file - and you can set the speed the file gets written

TIME_PER_LINE=0.01
SIZE=10_000          
HAPLOTYPES = 4 
MUTATION_RATE = 200  # 1 in 200
NUCLEOTIDES = "a g c t".split

individuals = ARGV[0].to_i

reference = []

(0..SIZE-1).each do | i |
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
    f1 = f[i]
    if rand(300) == 100          # switch haplotype on average every 300 bp
      h[i] = rand(HAPLOTYPES)      
    end
    h1 = h[i]
    # Calculate a probability for the nucleotide
    prob = rand * 2 
    prob = 1.0 if prob > 1
    # p reference[j],h[i] ,prob
    # p haplotypes[h1][i]

    f1.printf "%s\t%i\t%s\t%.2f\n",reference[j].join,h[i],haplotypes[h1][j],prob
    f1.flush
  end
  sleep TIME_PER_LINE
end
print "\nDone\n"
