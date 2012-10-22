# require "json"

class Genotype
  attr_reader :nuc
  def initialize rec = nil # , nuc=nil, prob=nil
    if rec
      raise "Record size error #{rec.join(' ')}, size #{rec.size}" if rec.size != 6
      @s_idx,@s_pos,@ref,@haplotype,@nuc,@s_prob = rec
    end
  end

  def idx
    @idx ||= @s_idx.to_i
  end

  def pos
    @pos ||= @s_pos.to_i
  end

  def prob
    @prob ||= @s_prob.to_f
  end

  def set_prob prob
    @prob = prob
    @s_prob = prob.to_s
  end

  def info
    @s_prob+nuc
  end

  def to_s
    "#{@s_idx} #{@s_pos} #{nuc} #{@s_prob}"
  end

  def serialize
    [@s_pos,@nuc,@s_prob].join("\t")
  end

  def deserialize list
    @s_pos,@nuc,@s_prob = list
    self
  end

  def == other
    # return false if other == :eof
    self.pos == other.pos and self.nuc == other.nuc
  end
end

module GenotypeSerialize

  def GenotypeSerialize::serialize list
    list.map { |g| g.serialize }.join("\n")
  end

  def GenotypeSerialize::deserialize buf
    buf.split(/\n/).map { |line| g = Genotype.new ; g.deserialize(line.split(/\t/)) }
  end
end
