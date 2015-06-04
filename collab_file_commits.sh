#!/bin/bash

# Copyright (C) 2015 Dawn M. Foster
# Licensed under GNU General Public License (GPL), version 3 or later: http://www.gnu.org/licenses/gpl.txt

# The purpose of this script is to find all of the people who have committed changes to a specific
# file using CVSAnaly data. It takes a list of commits from a CVSAnaly database in a csv file
# where one field in the header file is "file_id". This is likely the output from one of the other
# scripts in this set: files_committed.sh or files_committed_withfilepath.sh. The output generated
# from either of those scripts can be used as input for this one.
# More details on CVSAnaly: http://metricsgrimoire.github.io/CVSAnalY/
# Output is of the form: 
# file_id,commit_id,date,timezone,type,people_id,email

# WARNING: This can generate a massive amount of output for people who have edited a lot of files
# or frequently edited files.

# Note: this is NOT a general purpose script. I am using this with CVSAnaly and this script
#       is being used to generate specific output. I will only work in certain cases, and maybe only for me :)

# -i, --inputfile       FILE: Set the input filename (CSV file) where you want to do the search and replace
#                       This file should contain one email address per line.
#                       It should not contain a header row.
# -o, --outputfile      OUTFILE: Set the filename for the output file as OUTFILE where
#                       you want to store it. This file should not exist. If it does, original will be moved
#                       to /tmp and then overwritten.
# -d, --database        DATABASE: the database name to query.
# -u, --user-mysql      USER: the MySQL username.
# -p, --password-mysql  PASS: Not ideal, but you need to pass it a cleartext password.

# Read arguments from the command line and store them in variables

while [[ $# > 0 ]]
do
key="$1"

case $key in
     -i|--inputfile)
     FILE="$2"
     shift
     ;;
     -o|--outputfile)
     OUTFILE="$2"
     shift
     ;;
     -d|--database)
     DATABASE="$2"
     shift
     ;;
     -u|--user-mysql)
     USER="$2"
     shift
     ;;
     -p|--password-mysql)
     PASS="$2"
     shift
     ;;
        *)
            # unknown option
    ;;
esac

shift
done

# If outfile exists, make a backup and remove outfile to avoid appending new data to an old file.

if [ -f "$OUTFILE" ]
then
   cp $OUTFILE /tmp/outputfile.bak
   rm $OUTFILE
   echo ""
   echo "Your output file already existed. Original file moved to /tmp/outputfile.bak"
   echo ""
fi

# output message to make sure user has the correct details

echo "Reading input from $FILE"
echo "Output stored in $OUTFILE"

#### Get column number for file_id column ####

# read the first line of the CSV - containing column names as headers and store it in a variable

GETCOLS=$(head -n 1 $FILE)

# Set IFS to comma, but get the original IFS value to reset at the end of the script back to existing value.

OIFS=$IFS
IFS=,

# set column number to be used later in loop to get the column number for the file_id
# read the variable as a comma separated array in a loop to find file_id and get it's column number

COLNUM=1

for x in $GETCOLS
do
  if [ $x = "file_id" ]; then
     FILE_IDCOLNUM=$COLNUM
  fi
  ((COLNUM++))
done

#### Get list of people who collaborated on each file ####

i=0 	# keep track of which line of the file we're on.

# Loop through each line containing a commit and file_id to find the other people who have contributed
# to that file. Use sed to skip reading the first line (header line) to avoid passing bad data into 
# the first iteration of the mysql query. The first time through the loop, allow mysql to print a header
# line (no -N parameter) and create the file to be appended in the following loops. Suppress header lines
# with -N for all but the first iteration.

sed 1d $FILE | while read line; do
   FILE_ID=$(cut -d , -f $FILE_IDCOLNUM <<< "$line")
   if [ $i -eq 0 ]; then
      mysql  --user=$USER --password=$PASS --database=$DATABASE --execute="select actions.file_id, actions.commit_id, scmlog.date, ((scmlog.date_tz div 3600) +36) mod 24 - 12 as timezone, actions.type, people.id as people_id, people.email from actions, people, scmlog where actions.file_id=$FILE_ID and scmlog.id=actions.commit_id and scmlog.author_id=people.id;" > /tmp/outfile.tsv
   else
      mysql -N  --user=$USER --password=$PASS --database=$DATABASE --execute="select actions.file_id, actions.commit_id, scmlog.date, ((scmlog.date_tz div 3600) +36) mod 24 - 12 as timezone, actions.type, people.id as people_id, people.email from actions, people, scmlog where actions.file_id=$FILE_ID and scmlog.id=actions.commit_id and scmlog.author_id=people.id;" >> /tmp/outfile.tsv
   fi
   ((i++))
done

# Replace any existing commas with spaces

sed -i '.bak' "s/,/ /g" /tmp/outfile.tsv

# Convert file from tab delimited to comma delimited. What looks like a space is an embedded tab, since
# MacOS can't handle \t

sed 's/	/,/g' /tmp/outfile.tsv > $OUTFILE

# cleanup and remove temp files

rm /tmp/outfile.tsv /tmp/outfile.tsv.bak

# reset IFS back to original value before ending script.

IFS=$OIFS
