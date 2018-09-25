#!/bin/bash

##=======================================================================
#PBS -N gnu-par
#PBS -A P54048000 
#PBS -l walltime=06:00:00
#PBS -q premium
#PBS -k oe
#PBS -m a 
#PBS -M zarzycki@ucar.edu
#PBS -l select=1:ncpus=36:mem=109GB
################################################################

# use numcores = 32 for 1deg runs, 16 for high-res runs
NUMCORES=32
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt

CONFIG=f.asd2017.cesm20b05.FAMIPC6CLM5.ne0conus30x8_t12.exp211
OUTDIR=/glade/scratch/zarzycki/TEST-AR/

cd $OUTDIR

declare -a VARS=("U850" "V850" "TMQ")
for DATA_YEAR in {1980..2012}
do
  for VAR in "${VARS[@]}"
  do
    VARM1=$((DATA_YEAR-1))
    VARP1=$((DATA_YEAR+1))
    OUTNAME=${CONFIG}.cam.h2.${VAR}.${DATA_YEAR}010100Z-${DATA_YEAR}123118Z.nc
    FILES=`eval ls ${OUTDIR}/${CONFIG}.cam.h2.{$VARM1..$VARP1}*-00000.nc`
    LINECOMMAND="ncrcat -v date,${VAR} -d time,'${DATA_YEAR}-01-01 00:00:0.0','${DATA_YEAR}-12-31 18:00:0.0' ${FILES} ${OUTNAME}   "
    echo ${LINECOMMAND} >> ${COMMANDFILE}
  done
done

#### Use this for Cheyenne batch jobs
parallel --jobs ${NUMCORES} -u --sshloginfile $PBS_NODEFILE --workdir $PWD < ${COMMANDFILE}

rm ${COMMANDFILE}