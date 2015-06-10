#!/usr/bin/env python2

# Copyright (C) 2015 Dawn M. Foster
# Licensed under GNU General Public License (GPL), version 3 or later: http://www.gnu.org/licenses/gpl.txt

# The purpose of this script is to make sure I have one email address per person
# so for people using multiple email addresses, replace one email address with a 
# single main email address.

# This script replaces previous shell script versions: de-dup-email.sh, de-dup-email-mac.sh

# Note: this is NOT a general purpose script. I am using this with mlstats/CVSAnaly and this script
#       is being used to sanitize the output. I will only work in certain cases, and maybe only for me :)


import fileinput	# used for file operations
import re		# used to match regex
import shutil		# used to copy a file.
import os.path		# used to see if a file exists
import sys, getopt	# used to read options 

def usage():
    print "de-dup-email.py"
    print "Copyright (C) 2015 Dawn M. Foster"
    print "Licensed under GNU General Public License (GPL), version 3 or later: http://www.gnu.org/licenses/gpl.txt"
    print """
-h, --help
-i, --inputfile       FILE: Set the input filename (CSV file) where you want to do the search and replace
                      This file should be of a form (per line), similar to: thread subect,email,date,message_id
                      Most importantly, the file must be comma separated and contain email addresses.
                      CAUTION: if you have any other fields that contain email addresses, like mlstats message_id
                              This will clobber that field as well. You may need to tweak the sed command in this case.
-o, --outputfile      OUTFILE: Set the filename for the output file as OUTFILE where 
                      you want to store clean text. Note: sed also creates a .bak while editing this file
-e, --email-aliases   ALIASES: The file where the email aliases are stored. 
                      Each line should contain: old@example.com,new@example.com,# optional comment    
"""

def main(argv):
    input_file=''
    output_file=''
    aliases_file=''
    try: 
        opts, args = getopt.getopt(argv, "hi:o:e:", ["help","inputfile=","outputfile=","email-aliases="])
    except getopt.GetoptError:
        print 'Usage: de-dup-email.py -i <inputfile> -o <outputfile> -e <email-aliases file>'
        sys.exit(2)
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            usage()
            sys.exit(0)
        elif opt in ("-i", "--inputfile"):
            input_file = arg
        elif opt in ("-o", "--outputfile"):
            output_file = arg
        elif opt in ("-e", "--email-aliases"):
            aliases_file = arg

    # Output messages to make sure user has the correct details

    print 'Reading input from file', input_file
    print 'Transforming using file', aliases_file
    print 'Writing output to file', output_file


    # Copy the input_file to the output_file to leave the original file intact.
    # If output_file exists, make a backup copy

    if os.path.isfile(output_file):
        shutil.copyfile(output_file, '/tmp/outputfile.bak')
        print 'Output file already exists. Original was backed up at /tmp/outputfile.bak'

    shutil.copyfile(input_file, output_file)

    aliases = open(aliases_file, 'rb')

    # Loops through aliases file. Escaping characters that interfere with regex. Most notably + in emails.

    for row in aliases:
        email_list = row.split(',', 2) 
        old_email = re.escape(email_list[0])
        new_email = re.escape(email_list[1])

    # Loops through input file for every line in the aliases file
    # to replace emails with a single true email based on aliases file.
    # Because special chars were escaped, we now need to remove all of the extra \ chars
    # before printing the new result back to the file and avoid printing any extra blank lines

        for line in fileinput.input(output_file, inplace=True):
            line = re.sub(old_email, new_email, line.strip())
            line = re.sub(r'\\', '', line.strip())
            if line != '': print line.decode('string_escape')

if __name__ == "__main__":
   main(sys.argv[1:])

