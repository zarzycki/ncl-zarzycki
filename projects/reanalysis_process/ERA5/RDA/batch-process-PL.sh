#!/bin/bash

##=======================================================================
#PBS -N gen_nudge_betacast
#PBS -A P93300642
#PBS -l select=1:ncpus=32:mem=110GB
#PBS -l walltime=12:00:00
#PBS -q casper@casper-pbs
#PBS -j oe
################################################################

module load ncl
module load conda
conda activate npl

# use numcores = 32 for 1deg runs, 16 for high-res runs
NUMCORES=32
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt
GRIDCONFIG="ll025" # ll025 (pre-1979) or regn320 (1979-)
RDADS="ds633.0"      # ds633.4 (pre-1979) or ds630.0 (1979-)

for DATA_YEAR in {2022..2023}
do

#  #-- Add T files
 FILES=`find /glade/u/home/zarzycki/rda/${RDADS}/ -name "*e5*oper.an.pl.128_130_t.${GRIDCONFIG}sc.${DATA_YEAR}*nc"`
 for f in $FILES
 do
   LINECOMMAND="ncl process-PL.ncl 'filename=\"$f\"' 'VARIN=\"T\"' 'VAROUT=\"T400\"' 'LEVIN=\"400\"'      "
   echo ${LINECOMMAND} >> ${COMMANDFILE}
 done

  # Add Z files
  FILES=`find /glade/u/home/zarzycki/rda/${RDADS}/ -name "*e5*oper.an.pl.128_129_z.${GRIDCONFIG}sc.${DATA_YEAR}*nc"`
  for f in $FILES
  do
    LINECOMMAND="ncl process-PL.ncl 'filename=\"$f\"' 'VARIN=\"Z\"' 'VAROUT=\"Z300\"' 'LEVIN=\"300\"'      "
    echo ${LINECOMMAND} >> ${COMMANDFILE}
    LINECOMMAND="ncl process-PL.ncl 'filename=\"$f\"' 'VARIN=\"Z\"' 'VAROUT=\"Z500\"' 'LEVIN=\"500\"'      "
    echo ${LINECOMMAND} >> ${COMMANDFILE}
#     LINECOMMAND="ncl process-Z.ncl 'filename=\"$f\"' 'VARIN=\"Z\"' 'VAROUT=\"Z\"'    "
#     echo ${LINECOMMAND} >> ${COMMANDFILE}
  done

  # Add U files
  FILES=`find /glade/u/home/zarzycki/rda/${RDADS}/ -name "*e5*oper.an.pl.128_131_u.${GRIDCONFIG}uv.${DATA_YEAR}*nc"`
  for f in $FILES
  do
    LINECOMMAND="ncl process-PL.ncl 'filename=\"$f\"' 'VARIN=\"U\"' 'VAROUT=\"U850\"' 'LEVIN=\"850\"'      "
    echo ${LINECOMMAND} >> ${COMMANDFILE}
    #LINECOMMAND="ncl process-PL.ncl 'filename=\"$f\"' 'VARIN=\"U\"' 'VAROUT=\"U500\"' 'LEVIN=\"500\"'      "
    #echo ${LINECOMMAND} >> ${COMMANDFILE}
    #LINECOMMAND="ncl process-PL.ncl 'filename=\"$f\"' 'VARIN=\"U\"' 'VAROUT=\"U200\"' 'LEVIN=\"200\"'      "
    #echo ${LINECOMMAND} >> ${COMMANDFILE}
  done

  # Add V files
  FILES=`find /glade/u/home/zarzycki/rda/${RDADS}/ -name "*e5*oper.an.pl.128_132_v.${GRIDCONFIG}uv.${DATA_YEAR}*nc"`
  for f in $FILES
  do
    LINECOMMAND="ncl process-PL.ncl 'filename=\"$f\"' 'VARIN=\"V\"' 'VAROUT=\"V850\"' 'LEVIN=\"850\"'      "
    echo ${LINECOMMAND} >> ${COMMANDFILE}
    #LINECOMMAND="ncl process-PL.ncl 'filename=\"$f\"' 'VARIN=\"V\"' 'VAROUT=\"V500\"' 'LEVIN=\"500\"'      "
    #echo ${LINECOMMAND} >> ${COMMANDFILE}
    #LINECOMMAND="ncl process-PL.ncl 'filename=\"$f\"' 'VARIN=\"V\"' 'VAROUT=\"V200\"' 'LEVIN=\"200\"'      "
    #echo ${LINECOMMAND} >> ${COMMANDFILE}
  done

  # Add PSL files
  FILES=`find /glade/u/home/zarzycki/rda/${RDADS}/ -name "*e5*oper.an.sfc.128_151_msl.${GRIDCONFIG}sc.${DATA_YEAR}*nc"`
  for f in $FILES
  do
    LINECOMMAND="ncl process-PSL.ncl 'filename=\"$f\"' 'VARIN=\"MSL\"' 'VAROUT=\"PSL\"'    "
    echo ${LINECOMMAND} >> ${COMMANDFILE}
  done

  # Add UBOT files
  FILES=`find /glade/u/home/zarzycki/rda/${RDADS}/ -name "*e5*oper.an.sfc.128_165_10u.${GRIDCONFIG}sc.${DATA_YEAR}*nc"`
  for f in $FILES
  do
    LINECOMMAND="ncl process-PL.ncl 'filename=\"$f\"' 'VARIN=\"VAR_10U\"' 'VAROUT=\"UBOT\"' 'LEVIN=\"-999\"'      "
    echo ${LINECOMMAND} >> ${COMMANDFILE}
  done

  # Add UBOT files
  FILES=`find /glade/u/home/zarzycki/rda/${RDADS}/ -name "*e5*oper.an.sfc.128_166_10v.${GRIDCONFIG}sc.${DATA_YEAR}*nc"`
  for f in $FILES
  do
    LINECOMMAND="ncl process-PL.ncl 'filename=\"$f\"' 'VARIN=\"VAR_10V\"' 'VAROUT=\"VBOT\"' 'LEVIN=\"-999\"'      "
    echo ${LINECOMMAND} >> ${COMMANDFILE}
  done

done  # end years loop

#### Use this for Casper batch jobs
parallel --jobs ${NUMCORES} --workdir $PWD < ${COMMANDFILE}


rm ${COMMANDFILE}

