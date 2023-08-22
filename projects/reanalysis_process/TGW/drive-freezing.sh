#!/bin/bash -l

################################################################
#SBATCH -N 1                #Number of nodes
#SBATCH -t 40:00:00         #Time limit
#SBATCH -q premium          #Use the regular QOS
#SBATCH -L SCRATCH          #Job requires $SCRATCH file system
#SBATCH -C knl,quad,cache
################################################################

NUMCORES=8
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt

FILES=`find /global/cfs/cdirs/m2702/gsharing/tgw-wrf-conus/historical_1980_2019/three_hourly/ -name "*_three_hourly_2???-*nc" | sort -n`
for f in $FILES; do
  LINECOMMAND="ncl create-freezing.ncl 'f=\"$f\"'   "
  echo ${LINECOMMAND} >> ${COMMANDFILE}
done

parallel --jobs ${NUMCORES} --workdir $PWD < ${COMMANDFILE}
