# Line parser for SNP records

require 'filereader'
require 'genotype'

module ParseLine

  def ParseLine::tail_each_rec f
    FileReader::tail_each_line(f) do |line|
      yield line.strip.split(/\t/)
    end
  end

  def ParseLine::tail_each_genotype f
    tail_each_rec(f) do | rec |
      yield Genotype.new(rec)
    end
  end
end
