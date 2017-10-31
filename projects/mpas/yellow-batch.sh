#!/bin/bash

##=======================================================================
#BSUB -a poe                     # use LSF openmp elim
#BSUB -N
#BSUB -n 16                     # yellowstone setting
#BSUB -o out.%J                  # output filename
#BSUB -e out.%J                  # error filename
#BSUB -q regular                # queue
#BSUB -J recov-pres 
#BSUB -W 8:00                   # wall clock limit
#BSUB -P P54048000               # account number

################################################################

date

module load parallel

# >>   # print the name of the file containing the nodes allocated for parallel execution
# >>   echo "PBS Nodefile: $PBS_NODEFILE"
# >>   # print the names of the nodes allocated for parallel execution
# >>   cat $PBS_NODEFILE
# >>   echo "*************************************"
# >>   HOST_NODEFILE=$PBS_NODEFILE
# >> echo "LSF Hosts: $LSB_HOSTS"
# >> # create the file with the list of the nodes allocated
# >> HOST_NODEFILE=`pwd`/lsf_nodefile.$$
# >> echo $HOST_NODEFILE
# >> > $HOST_NODEFILE
# >> for host in $LSB_HOSTS; do
# >>   echo $host >> $HOST_NODEFILE
# >> done
# >> 
# >> PATH=$PATH:/glade/apps/opt/parallel/20140422/bin
# >> MANPATH=$MANPATH:/glade/apps/opt/parallel/20140422/share/man
# >> #prepend_path("PATH", "/glade/apps/opt/parallel/20140422/bin")
# >> #prepend_path("MANPATH", "/glade/apps/opt/parallel/20140422/share/man")

NUMJOBS=8
NUMCORES=4
CONFIG="mp15a-120a-US_t12.exp004"

rm commands2.txt
DIR=/glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.${CONFIG}/atm/hist/
FILELIST=()
ALLFILES=`ls ${DIR}/*h2*.nc | grep -v PRES.nc`    #Find all h2 files
shopt -s nullglob
for f in ${ALLFILES}
do
  # if h2 files doesn't have a corresponding PRES.nc, add it to FILELIST
  if [ ! -f ${f}.PRES.nc ]; then
    FILELIST+=($f)
  fi
done
ARRSIZE=${#FILELIST[@]}    # number of files still needing to be processed in $DIR
echo $ARRSIZE"... still needing to be processed"

# create new line in command file for 1 -> NUMCORES
for i in `seq 1 ${NUMJOBS}`;
do
  imin1=`expr $i - 1`
  f=${FILELIST[$imin1]}
  echo $f
  NCLCOMMAND="ncl recover-pressure.ncl 'histfilename=\"'${f}'\"'"
  echo ${NCLCOMMAND} >> commands2.txt
done
 
# Launch GNU parallel
#parallel --jobs 16 --sshloginfile $HOST_NODEFILE --workdir $PWD < commands2.txt 
parallel --jobs ${NUMCORES} --workdir $PWD < commands2.txt 

# Check if number of files still needing to be processed is greater than filesize chunk.
# if so, resubmit
if [ "$ARRSIZE" -gt "$NUMJOBS" ]; then
  echo "RESUBMIT"
  cd /glade/u/home/zarzycki/ncl/projects/mpas
  sed -i "s?^CONFIG.*?CONFIG=\"${CONFIG}\"?" yellow-batch.sh
  bsub < yellow-batch.sh
fi

date 
