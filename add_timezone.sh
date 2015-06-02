#!/bin/bash

# Copyright (C) 2015 Dawn M. Foster
# Licensed under GNU General Public License (GPL), version 3 or later: http://www.gnu.org/licenses/gpl.txt

# The purpose of this script is to take a comma separated csv file with mlstats data of form:
# subject,email_address,first_date,message_id,database
# and add time zone data to output the following:
# subject,email_address,first_date,first_date_tz,message_id,database

# Note: this is NOT a general purpose script. I am using this with mlstats and this script
#       is being used to sanitize the output. I will only work in certain cases, and maybe only for me :)

# -i, --inputfile	FILE: Set the input filename (CSV file) where you want to do the search and replace
#			This file should be of the form (per line): thread subect,email,date,message_id
#			It should not contain a header row.
# -o, --outputfile	OUTFILE: Set the filename for the output file as OUTFILE where 
#			you want to store it. This file should not exist. If it does, original will be moved
#			to /tmp and then overwritten.
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

# output message to make sure user has the correct details

echo "Reading input from $FILE"
echo "Output stored in $OUTFILE"

# If outfile exists, make a backup and remove outfile to avoid appending new data to an old file.

if [ -f "$OUTFILE" ]
then
   cp $OUTFILE /tmp/outputfile.bak
   rm $OUTFILE
   echo "Your output file already existed. Original file moved to /tmp/outputfile.bak" 
fi

# use comma as separator

IFS=,

# Create header row

echo "Subject,Email,Date,Timezone,Message_id,MailingList" > $OUTFILE

# Loop through input file and generate output file from existing input file data plus time zone data.
# This was a scrubbed CSV, so I needed to keep the data from the input file CSV, which is different in
# some cases from what is in the database.
# Time zone calculation converts seconds from GMT to hours from GMT - see line 80 here:
# https://github.com/VizGrimoire/VizGrimoireR/blob/alerts/examples/linux/mls-linux.R

while read SUBJECT EMAIL_ADDRESS FIRST_DATE MESSAGE_ID DATABASE; do
   TIMEZONE=$(mysql --user=$USER --password=$PASS --database=$DATABASE -se "SELECT ((first_date_tz div 3600) +36) mod 24 - 12 FROM messages WHERE message_id='$MESSAGE_ID';")
   echo "$SUBJECT,$EMAIL_ADDRESS,$FIRST_DATE,$TIMEZONE,$MESSAGE_ID,$DATABASE" >> $OUTFILE
done < $FILE


