#!/bin/bash

##=======================================================================
#PBS -N gnu-par
#PBS -A P05010048 
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

# Add T files
FILES=`find /glade/u/home/zarzycki/rda/ds630.0/ -name "*e5.oper.an.pl.128_130_t.regn320sc.2016*nc"`
for f in $FILES
do
  LINECOMMAND="ncl process-U.ncl 'filename=\"$f\"' 'VARIN=\"T\"' 'VAROUT=\"T400\"' 'LEVIN=\"400\"'      " 
  echo ${LINECOMMAND} >> ${COMMANDFILE}
done

# Add Z files
FILES=`find /glade/u/home/zarzycki/rda/ds630.0/ -name "*e5.oper.an.pl.128_129_z.regn320sc.2016*nc"`
for f in $FILES
do
  LINECOMMAND="ncl process-U.ncl 'filename=\"$f\"' 'VARIN=\"Z\"' 'VAROUT=\"Z300\"' 'LEVIN=\"300\"'      " 
  echo ${LINECOMMAND} >> ${COMMANDFILE}
  LINECOMMAND="ncl process-U.ncl 'filename=\"$f\"' 'VARIN=\"Z\"' 'VAROUT=\"Z500\"' 'LEVIN=\"500\"'      " 
  echo ${LINECOMMAND} >> ${COMMANDFILE}
  LINECOMMAND="ncl process-Z.ncl 'filename=\"$f\"' 'VARIN=\"Z\"' 'VAROUT=\"Z\"'    " 
  echo ${LINECOMMAND} >> ${COMMANDFILE}
done

# Add U files
FILES=`find /glade/u/home/zarzycki/rda/ds630.0/ -name "*e5.oper.an.pl.128_131_u.regn320uv.2016*nc"`
for f in $FILES
do
  LINECOMMAND="ncl process-U.ncl 'filename=\"$f\"' 'VARIN=\"U\"' 'VAROUT=\"U850\"' 'LEVIN=\"850\"'      " 
  echo ${LINECOMMAND} >> ${COMMANDFILE}
  LINECOMMAND="ncl process-U.ncl 'filename=\"$f\"' 'VARIN=\"U\"' 'VAROUT=\"UBOT\"' 'LEVIN=\"1000000\"'      " 
  echo ${LINECOMMAND} >> ${COMMANDFILE}
done

# Add V files
FILES=`find /glade/u/home/zarzycki/rda/ds630.0/ -name "*e5.oper.an.pl.128_132_v.regn320uv.2016*nc"`
for f in $FILES
do
  LINECOMMAND="ncl process-U.ncl 'filename=\"$f\"' 'VARIN=\"V\"' 'VAROUT=\"V850\"' 'LEVIN=\"850\"'      " 
  echo ${LINECOMMAND} >> ${COMMANDFILE}
  LINECOMMAND="ncl process-U.ncl 'filename=\"$f\"' 'VARIN=\"V\"' 'VAROUT=\"VBOT\"' 'LEVIN=\"1000000\"'      " 
  echo ${LINECOMMAND} >> ${COMMANDFILE}
done

# Add PSL files
FILES=`find /glade/u/home/zarzycki/rda/ds630.0/ -name "*e5.oper.an.sfc.128_151_msl.regn320sc.2016*nc"`
for f in $FILES
do
  LINECOMMAND="ncl process-PSL.ncl 'filename=\"$f\"' 'VARIN=\"MSL\"' 'VAROUT=\"PSL\"'    " 
  echo ${LINECOMMAND} >> ${COMMANDFILE}
done

# Add PSL files
FILES=`find /glade/u/home/zarzycki/rda/ds630.0/ -name "*e5.oper.an.sfc.128_151_msl.regn320sc.2016*nc"`
for f in $FILES
do
  LINECOMMAND="ncl process-PSL.ncl 'filename=\"$f\"' 'VARIN=\"MSL\"' 'VAROUT=\"PSL\"'    " 
  echo ${LINECOMMAND} >> ${COMMANDFILE}
done

#### Use this for Cheyenne batch jobs
parallel --jobs ${NUMCORES} -u --sshloginfile $PBS_NODEFILE --workdir $PWD < ${COMMANDFILE}

rm ${COMMANDFILE}

