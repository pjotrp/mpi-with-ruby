
class Genotype
  attr_reader :nuc
  def initialize pos, nuc=nil, prob=nil
    if nuc == nil
      raise "Record size error #{pos.join(' ')}, size #{pos.size}" if pos.size != 5
      @s_pos,@ref,@haplotype,@nuc,@s_prob = pos
    else
      @s_pos = pos ; @nuc = nuc ; @s_prob = prob
    end
    # Another validation - normally comment out
    # raise "Data problem" if prob < 0.0 or prob > 1.00 
  end

  def pos
    @pos ||= @s_pos.to_i
  end

  def prob
    @prob ||= @s_prob.to_f
  end

  def to_s
    "#{pos} #{nuc} #{prob}"
  end
end


