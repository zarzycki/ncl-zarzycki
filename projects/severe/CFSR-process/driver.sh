#!/bin/bash

##=======================================================================
#PBS -N cfsr-severe-pro
#PBS -A P54048000 
#PBS -l walltime=11:00:00
#PBS -q economy
#PBS -k oe
#PBS -m a 
#PBS -M zarzycki@ucar.edu
#PBS -l select=1:ncpus=36
################################################################

# GNUPARALLEL SETTINGS
module load parallel
NUMCORES=16
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt

# Year to process
YEAR=1998

# Where to store output files with severe parms
OUTPUTDIR=/glade/scratch/zarzycki/CFSR/CFSR-SEVERE/${YEAR}/
# Where to store grib raw CFSR files
CFSRRAWDIR=/glade/scratch/zarzycki/CFSR/${YEAR}/
# Where is the NCL code?
SCRIPTDIR=/glade/u/home/zarzycki/ncl/projects/severe/CFSR-process/

mkdir -p $CFSRRAWDIR
cd $CFSRRAWDIR

# Get CFSR raw data from RDA
cp /glade/p/rda/data/ds093.0/${YEAR}/pgbh06.*.${YEAR}*.tar .
for f in *.tar
do
  tar -xvf "$f"
done
rm *.tar

cd $SCRIPTDIR
mkdir -p ${OUTPUTDIR}

# Create commands.txt file for GNU parallel
rm ${COMMANDFILE}
dates=`ls ${CFSRRAWDIR}/pgbh06.*.grb2`
shopt -s nullglob
for f in $dates
do
  NCLCOMMAND="ncl cfsr-to-severe.ncl 'grb_filename=\"'${f}'\"' 'outDir=\"'${OUTPUTDIR}'\"'     "
  echo ${NCLCOMMAND} >> ${COMMANDFILE}
done

# Launch GNU parallel
parallel --jobs ${NUMCORES} -u --sshloginfile $PBS_NODEFILE --workdir $PWD < ${COMMANDFILE}

# Clean up
rm ${COMMANDFILE}
rm -rf $CFSRRAWDIR/*.grb2
