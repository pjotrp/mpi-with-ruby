# Generate input file

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
  (0..SIZE-1).each do | i |
    if rand(MUTATION_RATE) == 1
      haplotypes[h] << 'x'
    else
      haplotypes[h] << reference[i][rand(2)]
    end
  end
end

(1..individuals).each do | i |
  fn = "ind#{i}.tab"
  print "\nWriting #{fn}..."
  File.open(fn,"w") do | f |
    h = 0
    (0..SIZE-1).each do | i |
      if i % 300 == 0   
        h = rand(HAPLOTYPES)
      end
      prob = rand * 2
      prob = 1.0 if prob > 1
      f.printf "%s\t%i\t%s\t%.2f\n",reference[i],h,haplotypes[h][i],prob
    end
  end
end
