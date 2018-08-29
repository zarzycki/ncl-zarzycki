#!/bin/bash

##=======================================================================
#PBS -N gnu-par
#PBS -A P54048000 
#PBS -l walltime=01:00:00
#PBS -q premium
#PBS -k oe
#PBS -m a 
#PBS -M zarzycki@ucar.edu
#PBS -l select=1:ncpus=36:mem=109GB
################################################################

NUMCORES=16
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt

#WGTFILE=/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_ne30_to_1x1glob_patch.nc
#CAMDIR=/glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.ne30_g16.exp212/atm/hist/
WGTFILE=~/scratch/map_conus_30_x8_to_0.125x0.125_GLOB.nc
CAMDIR=/glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.ne0conus30x8_t12.exp211/atm/hist/
OUTDIR=/glade/scratch/zarzycki/TEST-AR/
mkdir -p ${OUTDIR}
FILES=`ls ${CAMDIR}/*.cam.h2.1979*.nc ${CAMDIR}/*.cam.h2.198*.nc`
for f in $FILES
do
  base=`basename $f`
  LINECOMMAND="ncks -v date,U850,V850,PRECT,TMQ -d time,,,1 ${f} ${OUTDIR}/${base}_tmp1.nc ; ncremap -i ${OUTDIR}/${base}_tmp1.nc -o ${OUTDIR}/${base}_tmp2.nc -m ${WGTFILE} ; mv ${OUTDIR}/${base}_tmp2.nc ${OUTDIR}/${base} ; rm ${OUTDIR}/${base}_tmp*.nc"
  echo ${LINECOMMAND} >> ${COMMANDFILE}
done

#### Use this for Cheyenne batch jobs
parallel --jobs ${NUMCORES} -u --sshloginfile $PBS_NODEFILE --workdir $PWD < ${COMMANDFILE}

rm ${COMMANDFILE}

