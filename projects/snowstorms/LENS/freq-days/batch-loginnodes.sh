#!/bin/bash

date

module load parallel

NUMCORES=2
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt

rm ${COMMANDFILE}
for ii in {001..035};
do
  LINECOMMAND="python ptype-freq.py ${ii} " 
  echo ${LINECOMMAND} >> ${COMMANDFILE}
done

# Launch GNU parallel
parallel --jobs ${NUMCORES} < ${COMMANDFILE}

rm ${COMMANDFILE}

date 
