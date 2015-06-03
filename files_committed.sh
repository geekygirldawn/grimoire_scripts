#!/bin/bash

# Copyright (C) 2015 Dawn M. Foster
# Licensed under GNU General Public License (GPL), version 3 or later: http://www.gnu.org/licenses/gpl.txt

# The purpose of this script is to take a list of email addresses (one per line) and find all
# of their commits (using a database generated by CVSAnaly - pre-requisite). In addition to finding
# their commits, it also displays each file changed in this commit with the type of change made.
# More details on CVSAnaly: http://metricsgrimoire.github.io/CVSAnalY/
# Output is of the form:
# commit_id,date,timezone,file_id,type,people_id,email

# Note: this is NOT a general purpose script. I am using this with CVSAnaly and this script
#       is being used to generate specific output. I will only work in certain cases, and maybe only for me :)

# -i, --inputfile	FILE: Set the input filename (CSV file) where you want to do the search and replace
#			This file should contain one email address per line.
#			It should not contain a header row.
# -o, --outputfile	OUTFILE: Set the filename for the output file as OUTFILE where 
#			you want to store it. This file should not exist. If it does, original will be moved
#			to /tmp and then overwritten.
# -d, --database	DATABASE: the database name to query.
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

# Loop through input file and generate output file from existing input file data plus time zone data.
# This was a scrubbed CSV, so I needed to keep the data from the input file CSV, which is different in
# some cases from what is in the database. i is an increment to keep track of iteration and only print
# header for first iteration.
# Time zone calculation converts seconds from GMT to hours from GMT - see line 80 here:
# https://github.com/VizGrimoire/VizGrimoireR/blob/alerts/examples/linux/mls-linux.R
# The first time through the loop, allow mysql to print a header
# line (no -N parameter) and create the file to be appended in the following loops. Suppress header lines
# with -N for all but the first iteration.

i=0

while read EMAIL_ADDRESS; do
   if [ $i -eq 0 ]; then
      mysql --user=$USER --password=$PASS --database=$DATABASE --execute="select scmlog.id as commit_id, scmlog.date, ((scmlog.date_tz div 3600) +36) mod 24 - 12 as timezone, actions.file_id, actions.type, people.id as people_id, people.email from scmlog, people, actions where people.email='$EMAIL_ADDRESS' and scmlog.author_id=people.id and scmlog.id=actions.commit_id;" > /tmp/outfile.tsv
   else
      mysql -N --user=$USER --password=$PASS --database=$DATABASE --execute="select scmlog.id as commit_id, scmlog.date, ((scmlog.date_tz div 3600) +36) mod 24 - 12 as timezone, actions.file_id, actions.type, people.id as people_id, people.email from scmlog, people, actions where people.email='$EMAIL_ADDRESS' and scmlog.author_id=people.id and scmlog.id=actions.commit_id;" >> /tmp/outfile.tsv
   fi
   ((i++))
done < $FILE

# Convert file from tab delimited to comma delimited. What looks like a space is an embedded tab, since
# MacOS can't handle \t

sed 's/	/,/g' /tmp/outfile.tsv > $OUTFILE

# cleanup and remove temp file

rm /tmp/outfile.tsv 
