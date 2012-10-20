module GenomeSection

  # Split the genome into smaller sections
  def GenomeSection::each f,do_split,size,threshold
    section = []
    ParseLine::tail_each_genotype(f) do | g |
      section << g
      if do_split and section.size > size and g.prob > threshold
        yield section
        section = [section.last]
      end
    end
    yield section
  end

end

