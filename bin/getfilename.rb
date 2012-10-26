# Transform pid to filename
# 
# The first input parameter gets the file to parse, the second gives divides
# the PID in equal sections. A third parameter will execute the program. For
# the current job we fire up (at least) 3 processes on each MPI node. The list
# contains the base input file name (a BAM file), which is used for processing.
# This list is 1/3rd the size of the number of processes. Process 0,1,2 should
# get the same file, and 3,4,5 etc.
#
# One nicety is that all FILENAME fields will be replaced too. This can be used for output.

$: << './lib'

fn=ARGV.shift
divide=2
if par=ARGV.shift
  divide = par.to_i
  exec=ARGV.shift
end

pid = MPI::Comm::WORLD.rank()   # the rank of the MPI process
num_processes = MPI::Comm::WORLD.size()    # the number of processes

section_size = num_processes/divide
index = pid % section_size

datafilen=File.open(fn).readlines[index].strip
par_s="#{datafilen} #{ARGV.join(' ')}"

if exec
  if exec =~ /FILENAME/
    par_s=ARGV.join(' ')
    exec = exec.gsub(/FILENAME/,File::basename(datafilen))
  end
  par_s2 = par_s.gsub(/FILENAME/,File::basename(datafilen)) 
  $stderr.print "\nReading pid #{pid} from <#{fn}> with divisor <#{divide}> exec <#{exec}>, and <#{par_s2}>" 
  Kernel.system "#{exec} #{par_s2}"
else
  print par_s
end
