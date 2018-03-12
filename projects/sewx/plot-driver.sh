#!/bin/bash

##=======================================================================
#BSUB -a poe                     # use LSF openmp elim
#BSUB -N
#BSUB -n 1                      # yellowstone setting
#BSUB -o ncl_up.%J                  # output filename
#BSUB -e ncl_up.%J                  # error filename
#BSUB -q geyser                 # queue
#BSUB -J upload_ncl
#BSUB -W 10:00                    # wall clock limit
#BSUB -P P54048000               # account number
##=======================================================================
module load ncl
###############################################################################
yearstr=2018
monthstr=01
daystr=04
cyclestr=00
cyclestrsec=00000
###############################################################################
nclweightfile=$1
runDir=$2
path_to_ncl=/glade/u/home/zarzycki/sewx-cam-forecast/plotting_ncl/
htmlFolder=/glade/u/home/zarzycki/ncl/projects/sewx/
  
	filenames=`ls ${runDir}/*h0*.nc`
	numfiles=`ls ${runDir}/*h0*.nc | wc -l`
	echo $numfiles

  mkdir -p ${runDir}/BAK
  cp ${filenames} ${runDir}/BAK

   VARS=PRECLav,PRECCav,PRECBSN,PRECBRA,PRECBIP,PRECBFZ
 
   for i in `seq 1 ${numfiles}`;
   do
     thisFile=`echo $filenames | cut -d" " -f${i}`
     if [ "$i" -eq 1 ] ; then
       ncks -v ${VARS} ${thisFile} ${runDir}/sum${i}.nc
       ncks -A -v ${VARS} ${runDir}/sum${i}.nc ${thisFile}
       rm ${runDir}/sum${i}.nc
     else
       iminus1=`expr $i - 1`
       lastFile=`echo $filenames | cut -d" " -f${iminus1}`
       ncrcat -v ${VARS} ${thisFile} ${lastFile} ${runDir}/tmpfile2.nc
       ncra -h -O -y ttl ${runDir}/tmpfile2.nc ${runDir}/sum${i}.nc
       ncap2 -A -s 'time=time+0.0625' ${runDir}/sum${i}.nc ${runDir}/sum${i}.nc
       ncks -A -v ${VARS} ${runDir}/sum${i}.nc ${thisFile}
       rm ${runDir}/sum${i}.nc ${runDir}/tmpfile2.nc
     fi
   done 
		
		sleep 5
		echo "Found at least one file"
		echo $filenames
		cd ${htmlFolder}
		newfiles=`ls ${runDir}/*h0*-00000.nc ${runDir}/*h0*-21600.nc ${runDir}/*h0*-43200.nc ${runDir}/*h0*-64800.nc`
		for f in $newfiles
		do
			echo "Processing $f"
 			ncl ${path_to_ncl}/weatherplot.ncl inisec=$cyclestrsec iniday=$daystr inimon=$monthstr iniyear=$yearstr 'filename="'${f}'"' 'wgt_file="'${nclweightfile}'"' > ncl.output 2>&1
 			if [ grep FileReadVar ncl.output ]; then
 				sleep 5
 				echo "Found an error"
 				ncl ${path_to_ncl}/weatherplot.ncl inisec=$cyclestrsec iniday=$daystr inimon=$monthstr iniyear=$yearstr 'filename="'${f}'"' 'wgt_file="'${nclweightfile}'"'
 			fi
 			#rm ncl.output
		done
		
		## Trim whitespace around pngs
		genpngs=`ls *png`
		for g in $genpngs
		do
			convert -trim +repage $g -colors 255 $g
		done
		    
mkdir ${yearstr}${monthstr}${daystr}${cyclestr}
mv *.png *.txt atcf.tempest* ${yearstr}${monthstr}${daystr}${cyclestr}