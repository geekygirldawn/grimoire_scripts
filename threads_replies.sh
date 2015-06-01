#!/bin/bash

# This script is used with mlstats databases find all of the messages within a certain year
# that a person has started or replied to. It then retrieves all of the messages within 
# each thread to find the other people who contributed to the same thread.
# thread subject, email address, date and message_id are stored in the final output file.
# A bunch of temporary, intermediate files are also written and are never cleaned up,
# since I use them for debugging, so you'll need to do some manual clean-up after a run.
# These temporary files can be found in the output directory.

# -e, --email		EMAIL: partial email string that can match multiple email address.
#			do select * from people with this string to confirm first. 
#			Use select * from people on partial name to look for other email addresses used.
# -d, --database	DATABASE: mlstats database where data can be found for this person
# -y, --year		YEAR: year that you want the data from
# -o, --output-dir	DIR: where the output and wip files will be stored. This directory must already exist.

# set default values for command line arguments

EMAIL=example
DATABASE=mlstats
YEAR=2014
DIR=/tmp

# Read arguments from the command line and store them in variables

while [[ $# > 0 ]]
do
key="$1"

case $key in
     -e|--email)
     EMAIL="$2"
     shift
     ;;
     -d|--database)
     DATABASE="$2"
     shift
     ;;
     -y|--year)
     YEAR="$2"
     shift
     ;;
     -o|--output-dir)
     DIR="$2"
     shift
     ;;
        *)
            # unknown option
    ;;
esac

shift
done

# get all thread message_ids for an author keyed on email address

/usr/local/bin/mysql --user=root --database=$DATABASE --execute="
   select m.subject from messages m, messages_people mp 
          where mp.message_id=m.message_id and mp.email_address like '%$EMAIL%' 
             and mp.type_of_recipient='From' and year(m.first_date)=$YEAR;" > $DIR/threadsubjects-$EMAIL.csv

# Check to see if the first mysql query had a result. If so, continue script, if not exit.

if [ -s "$DIR/threadsubjects-$EMAIL.csv" ]
then
   echo "Analyzing data for $EMAIL in $DATABASE for $YEAR."
   echo "Result will be stored in $DIR/threadreplies-final-$EMAIL-$YEAR.csv"
else
   echo "No data found for $EMAIL in $DATABASE for $YEAR"
   exit
fi

# remove the reply indicator to get the main thread subject NEED TO ADD RE: also (no case insensitive on mac)

sed "s/Re: //" $DIR/threadsubjects-$EMAIL.csv > $DIR/threadsubjects-re-$EMAIL.csv

# remove duplicate lines

awk '!a[$0]++' $DIR/threadsubjects-re-$EMAIL.csv > $DIR/threadsubjects-dups-$EMAIL.csv

# remove the initial header line (remove 1st line of file)

tail -n +2 $DIR/threadsubjects-dups-$EMAIL.csv > $DIR/threadsubjects-done-$EMAIL.csv

# remove file appended in while if exists

if [ -f "$DIR/threadreplies-$EMAIL.csv" ]
then 
   rm $DIR/threadreplies-$EMAIL.csv 
fi

# iterate through the file by line

while read p; do
  /usr/local/bin/mysql --user=root --database=$DATABASE --execute="
     select m.subject, mp.email_address, m.first_date, m.message_id from messages m, messages_people mp 
     where mp.message_id=m.message_id and m.subject like '%$p' 
       and mp.type_of_recipient='From' and year(m.first_date)=$YEAR;" >> $DIR/threadreplies-$EMAIL.csv
done < $DIR/threadsubjects-done-$EMAIL.csv 

# remove header lines throughout file

sed '/message_id/d' $DIR/threadreplies-$EMAIL.csv > $DIR/threadreplies-final-$EMAIL-$YEAR.csv
