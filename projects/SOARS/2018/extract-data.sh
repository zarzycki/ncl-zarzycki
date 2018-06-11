#!/bin/bash

##=============================================================
#PBS -N extract-points
#PBS -A P54048000 
#PBS -l walltime=00:59:00
#PBS -q premium
#PBS -k oe
#PBS -m a 
#PBS -M zarzycki@ucar.edu
#PBS -l select=1:ncpus=36
################################################################

DATADIR=/glade/u/home/zarzycki/scratch/SOARS-2018/
ENSMEM=003
SIMYRS=1979_2012     # 1979_2012, RCP85_2070_2099, 
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
while IFS=, read -r ix station lat lon city
do
  echo "$ix"
  slabstr="${slabstr} -d ncol,${ix}"
done < indices.csv
echo $slabstr

declare -a VAR=("PRECT" "TMQ" "PSL" "UBOT" "VBOT" "TS")
declare -a HXS=("h2"    "h2"  "h4"  "h4"   "h4"   "h4")

if [ ${SIMYRS} == "1979_2012" ]; then
  YEARSTRARR=`seq 1980 2009`
else
  YEARSTRARR=`seq 2070 2099`
fi

#FILES=${DATADIR}/*.${SIMYRS}.${ENSMEM}.*.PRECT.*.nc
for yr in ${YEARSTRARR[@]};
do
  fin=${DATADIR}/f.e13.FAMIPC5.ne120_ne120.${SIMYRS}.${ENSMEM}.cam.h2.PRECT.${yr}010100Z-${yr}123118Z.nc
  for v in "${!VAR[@]}" 
  do
    f="${fin//PRECT/${VAR[$v]}}"
    f="${f//h2/${HXS[$v]}}"
    if [ ${HXS[$v]} == "h4" ];
    then
      f="${f//123118Z/123121Z}"
    fi
    echo "Processing $f file..."
    base=$(basename $f)
    fout=${OUTDIR}/${base}.sub.nc
    NCLCOMMAND="   ncks -O ${slabstr} -v lat,lon,${VAR[$v]} ${f} ${fout}   "
    echo ${NCLCOMMAND} >> ${COMMANDFILE}
  done
done

# Launch GNU parallel
parallel --jobs ${NUMCORES} -u --sshloginfile ${PBS_NODEFILE} --workdir ${PWD} < ${COMMANDFILE}
#parallel --jobs ${NUMCORES} -u < ${COMMANDFILE}

endtime=$(date -u +"%s")
tottime=$(($endtime-$starttime))

printf "${tottime}\n" >> timing.txt