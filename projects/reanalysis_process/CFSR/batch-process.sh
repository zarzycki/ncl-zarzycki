#!/bin/bash

# use numcores = 32 for 1deg runs, 16 for high-res runs
NUMCORES=1
TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt

for DATA_YEAR in {2012..2015}
do
  LINECOMMAND="/bin/bash ./driver-CFS.sh ${DATA_YEAR}"
  echo ${LINECOMMAND} >> ${COMMANDFILE}
done

parallel --jobs ${NUMCORES} --workdir $PWD < ${COMMANDFILE}

rm ${COMMANDFILE}

