#!/bin/bash -l

################################################################
#>#PBS -N test_gnu
#>#PBS -A P54048000 
#>#PBS -l walltime=01:49:00
#>#PBS -q premium
#>#PBS -k oe
#>#PBS -m a 
#>#PBS -M zarzycki@ucar.edu
#>#PBS -l select=1:ncpus=36:mem=109GB
################################################################
#SBATCH -N 1                #Use 2 nodes
#SBATCH -t 06:00:00         #Set 30 minute time limit
#SBATCH -q regular          #Use the regular QOS
#SBATCH -L SCRATCH          #Job requires $SCRATCH file system
#SBATCH -C knl,quad,cache   #Use KNL nodes in quad cache format (default, recommended)
################################################################

GRID=EXT
CONFIG=dtime900.002

starttime=$(date -u +"%s")

module load parallel
module load ncl 

NUMCORES=8
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt

nclweightfile="/global/homes/c/czarzyck/scratch/maps/hyperion/map_ne0np4natlantic${GRID,,}.ne30x4_to_2.0x2.0_GLOB.nc"
for f in /global/homes/c/czarzyck/scratch/hyperion/CHEY.VR28.NATL.${GRID}.CAM5.4CLM5.0.${CONFIG}/atm/hist/*.h2.*.nc
do
  #ncl process-vort.ncl 'infile="'${f}'"' 'wgt_file="'${nclweightfile}'"'
  NCLCOMMAND="ncl process-vort.ncl 'infile=\"'${f}'\"' 'wgt_file=\"'${nclweightfile}'\"'     "
  echo ${NCLCOMMAND} >> ${COMMANDFILE}
done

# Launch GNU parallel
#parallel --jobs ${NUMCORES} -u --sshloginfile ${PBS_NODEFILE} --workdir ${PWD} < ${COMMANDFILE}
parallel --jobs ${NUMCORES} -u < ${COMMANDFILE}

endtime=$(date -u +"%s")
tottime=$(($endtime-$starttime))

rm ${COMMANDFILE}

printf "${tottime}\n" >> timing.txt
