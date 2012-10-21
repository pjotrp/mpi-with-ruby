
class Genotype
  attr_reader :nuc
  def initialize rec # , nuc=nil, prob=nil
    raise "Record size error #{rec.join(' ')}, size #{rec.size}" if rec.size != 6
    @s_idx,@s_pos,@ref,@haplotype,@nuc,@s_prob = rec
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

  def to_s
    "#{@s_idx} #{@s_pos} #{nuc} #{@s_prob}"
  end
end


