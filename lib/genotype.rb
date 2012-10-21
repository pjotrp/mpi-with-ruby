
class Genotype
  attr_reader :idx, :nuc
  def initialize rec # , nuc=nil, prob=nil
    raise "Record size error #{rec.join(' ')}, size #{rec.size}" if rec.size != 6
    @idx,@s_pos,@ref,@haplotype,@nuc,@s_prob = rec
  end

  def pos
    @pos ||= @s_pos.to_i
  end

  def prob
    @prob ||= @s_prob.to_f
  end

  def to_s
    "#{idx} #{@s_pos} #{nuc} #{@s_prob}"
  end
end


