#!/bin/bash -l

################################################################
#PBS -N test_gnu
#PBS -A P54048000 
#PBS -l walltime=10:49:00
#PBS -q premium
#PBS -k oe
#PBS -m a 
#PBS -M zarzycki@ucar.edu
#PBS -l select=1:ncpus=36:mem=109GB
################################################################
#> #SBATCH -N 1                #Use 2 nodes
#> #SBATCH -t 07:59:00         #Set 30 minute time limit
#> #SBATCH -q regular          #Use the regular QOS
#> #SBATCH -L SCRATCH          #Job requires $SCRATCH file system
#> #SBATCH -C knl,quad,cache   #Use KNL nodes in quad cache format (default, recommended)
################################################################

starttime=$(date -u +"%s")

module load parallel
module load ncl 

NUMCORES=8
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt

#FILES=`find /glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.mp120a_g16.exp214/atm/hist/ -name "*h2.???4*"`
#FILES=`find /glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.mp120a_g16.exp214/atm/hist/ -name "*h2.*"`
FILES=`find /glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.mp15a-120a-US_t12.exp213/atm/hist/ -name "*h2.201?*"`

for f in ${FILES}
do
  NCLCOMMAND="ncl create-files.ncl 'f2name=\"'${f}'\"' 'nlfile=\"nl.ASD.mp15a-120a-US\"'     "
  echo ${NCLCOMMAND} >> ${COMMANDFILE}
done

# Launch GNU parallel
parallel --jobs ${NUMCORES} -u --sshloginfile ${PBS_NODEFILE} --workdir ${PWD} < ${COMMANDFILE}
#parallel --jobs ${NUMCORES} -u < ${COMMANDFILE}

endtime=$(date -u +"%s")
tottime=$(($endtime-$starttime))

rm ${COMMANDFILE}

printf "${tottime}\n" >> timing.txt


