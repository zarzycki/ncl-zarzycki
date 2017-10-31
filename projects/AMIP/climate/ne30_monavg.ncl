#!/bin/bash

##=======================================================================
#BSUB -a poe                     # use LSF openmp elim
#BSUB -N
#BSUB -n 1                      # yellowstone setting
#BSUB -o out.%J                  # output filename
#BSUB -e out.%J                  # error filename
#BSUB -q geyser                 # queue
#BSUB -J mon_avg_ne30
#BSUB -W 23:55                    # wall clock limit
#BSUB -P P35201098               # account number

################################################################


for year in `seq 1994 1998`; 
do

cd /glade/scratch/zarzycki/ne30amip/$year

################################################################

echo "Checking count of files in directory is good"
h0size=$(ls *cam.h0*$year* | wc -l)
h2size=$(ls *cam.h2*$year* | wc -l)
h3size=$(ls *cam.h3*$year* | wc -l)

if [ $h0size -ne 365 ]
then
    echo "h0 failed count check"
    htarerror=1
# elif [ $h2size -ne 92 ]
# then
#     echo "h2 failed count check"
#     htarerror=1
elif [ $h3size -ne 365 ]
then
    echo "h3 failed count check"
    htarerror=1
else
    echo "All files passed count check"
    htarerror=0
fi;

############################################################

echo "Checking size of files to make sure they are equal"

for filetype in `seq 1 3`; do
    # Set filestrings
    if [ $filetype == 1 ]
    then
        filestr="h0"
    elif [ $filetype == 2 ]
    then
        filestr="h2"
    elif [ $filetype == 3 ]
    then
        filestr="h3"
    else
        echo "No filestring set"
    fi;
    echo "New filestring set set as $filestr"
    
    ###### Check file size
    filesizeprev=-999
    for f in /glade/scratch/zarzycki/ne30amip/$year/*cam.$filestr*$year*
    do
        filesize=$(stat -c %s $f)
        if [ $filesizeprev = -999 ]
        then
            echo "$f is the first file"
            filesizeprev=$filesize
        elif [ $filesize -ne $filesizeprev ]
        then
            echo "$f FAILED file size check"
            htarerror=1
            break
        else
            donothing=0
            #echo "$f passed file size check"
        fi;
    done
    
done

echo "the status of the error check is... $htarerror"

################################################################
# Average files
################################################################

if [ $htarerror = 0 ]
then

    for filetype in `seq 1 3`; do
    
    # Set filestrings
        if [ $filetype == 1 ]
            then
            filestr="h0"
        elif [ $filetype == 2 ]
        then
            filestr="h2"
        elif [ $filetype == 3 ]
        then
            filestr="h3"
        else
            echo "No filestring set"
        fi;
    
        echo "Filestring in average loop set to $filestr"
        
        for month in `seq 1 12`;
        do
            monthpad=`printf "%02d\n" $month`
            echo "Doing $monthpad averages for $filestr files"
            
            ncrcat "ne30amip.cam."$filestr"."$year"-"$monthpad"-"* monthtot.nc
            ncra monthtot.nc "ne30amip_monavg_"$filestr"."$year"-"$monthpad".nc"
            rm monthtot.nc
        done
    
    done
else
    echo "Errors were detected, exiting while NOT complete"
fi;

echo "Moving files"
mv *monavg*.nc /glade/scratch/zarzycki/ne30amip_monthly/

done
