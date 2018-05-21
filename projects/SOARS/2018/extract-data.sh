#!/bin/bash

##=============================================================
#PBS -N extract-points
#PBS -A P54048000 
#PBS -l walltime=00:29:00
#PBS -q premium
#PBS -k oe
#PBS -m a 
#PBS -M zarzycki@ucar.edu
#PBS -l select=1:ncpus=36
################################################################

DATADIR=/glade/u/home/zarzycki/scratch/archive/CHEY.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900/atm/hist/
OUTDIR=/glade/scratch/zarzycki/tmp/
NUMCORES=16

starttime=$(date -u +"%s")

module load parallel
module load nco
module load ncl

TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt

ncl find-ix.ncl
slabstr=""
while IFS=, read -r ix city lat lon
do
  echo "$ix"
  slabstr="${slabstr} -d ncol,${ix}"
done < indices.csv
echo $slabstr

FILES=${DATADIR}/*.h2.*nc
for f in $FILES
do
  echo "Processing $f file..."
  base=$(basename $f)
  fout=${OUTDIR}/${base}.sub.nc
  NCLCOMMAND="   ncks -O ${slabstr} -v lat,lon,PRECT,PSL,TMQ,TS ${f} ${fout}   "
  echo ${NCLCOMMAND} >> ${COMMANDFILE}
done

# Launch GNU parallel
parallel --jobs ${NUMCORES} -u --sshloginfile ${PBS_NODEFILE} --workdir ${PWD} < ${COMMANDFILE}
#parallel --jobs ${NUMCORES} -u < ${COMMANDFILE}

endtime=$(date -u +"%s")
tottime=$(($endtime-$starttime))

printf "${tottime}\n" >> timing.txt
