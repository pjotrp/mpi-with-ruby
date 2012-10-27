# require "json"

class Genotype
  attr_reader :nuc
  def initialize rec = nil # , nuc=nil, prob=nil
    if rec
      size = rec.size
      if size == 4
        @style = :sambamba
        # sambamba style "62944071", "T", "T,C", "13.3523"
        @s_pos,@ref,nucs,@s_score = rec
        @nuc = nucs.split(/,/) - [@ref]
      elsif size == 6
        @style = :native
        @s_idx,@s_pos,@ref,@haplotype,@nuc,@s_prob = rec
      else
        raise "Record size error #{rec.join(' ')}, size #{rec.size}" 
      end
    end
  end

  def idx
    @idx ||= @s_idx.to_i
  end

  def pos
    @pos ||= @s_pos.to_i
  end

  def prob
    if @style == :sambamba
      @prob ||= 1-1.0/10**(@s_score.to_f/10)
    else
      @prob ||= @s_prob.to_f
    end
  end

  def set_prob prob
    @prob = prob
    @s_prob = prob.to_s
  end

  def info
    @s_prob+nuc
  end

  def to_s
    "#{@s_idx} #{@s_pos} #{nuc} #{prob}"+(@s_score ? " "+@s_score : "") 
  end

  def serialize
    [@s_pos,@nuc,@s_prob].join("\t")
  end

  def deserialize list
    @s_pos,@nuc,@s_prob = list
    self
  end

  def == other
    self.pos == other.pos and self.nuc == other.nuc
  end
end

module GenotypeSerialize

  # List of genotypes
  def GenotypeSerialize::serialize list
    list.map { |g| g.serialize }.join("\n")
  end

  def GenotypeSerialize::deserialize buf
    buf.split(/\n/).map { |line| g = Genotype.new ; g.deserialize(line.split(/\t/)) }
  end
end
