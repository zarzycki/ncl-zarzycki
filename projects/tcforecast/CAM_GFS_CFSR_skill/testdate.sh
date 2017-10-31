#!/bin/bash
# Create a wordlist based on dates in the format
# ddmmyyyy
# date doesnt seem to like certain dates resulting in a 
# 'date: invalid date 'yyyy-mm-dd -d 1day' 
#
# Although the input needs to be yyyy-mm-dd
# the output with the below script will be ddmmyyyy
# Its slow and suppose it would be quicker if it wasnt 
# 'teed' to screen, but what else are you gonna stare at..
#
echo "Enter the starting date"
echo "must be in the format yyyy-mm-dd"
(tput bold && tput setaf 1)
read START_DATE
(tput sgr 0) 
echo "Enter the ending date"
echo "must be in the format yyyy-mm-dd"
(tput bold && tput setaf 1)
read END_DATE
(tput sgr 0)
# List all dates in between the above dates

echo $START_DATE | tee r_dates.txt
while true
do
START_DATE=$( date +%Y-%m-%d -d "$START_DATE -d 1day" )
echo $START_DATE | tee -a r_dates.txt
if [ "$START_DATE" == "$END_DATE" ]
then 
awk -F- '{print $3 $2 $1}' r_dates.txt > datelist.txt
rm r_dates.txt
(tput bold && tput setaf 1)
echo "wordlist 'datelist.txt' created"
(tput sgr 0)
exit
fi
done
