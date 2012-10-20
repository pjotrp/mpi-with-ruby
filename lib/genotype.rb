class Genotype
  attr_reader :pos, :nuc, :prob
  def initialize pos, nuc=nil, prob=nil
    if nuc == nil
      raise "Record size error #{pos.join(' ')}, size #{pos.size}" if pos.size != 5
      @pos,@ref,@haplotype,@nuc,@prob = pos
    else
      @pos = pos ; @nuc = nuc ; @prob = prob
    end
    # Another validation - normally comment out
    # raise "Data problem" if @prob.to_f < 0.0 or @prob.to_f > 1.00 
  end

  def to_s
    "#{pos} #{nuc} #{prob}"
  end
end


