Scripts for Metrics Grimoire
==================

Description
-----------
This repo contains scripts that I use with [mlstats](https://github.com/MetricsGrimoire/MailingListStats)
and [CVSAnaly](https://github.com/MetricsGrimoire/CVSAnalY) to run queries and do some analysis on the data.

Caveats
-------
These scripts are stored here for my convenience. They may or may not be useful to anyone else,
and they are a bit rough and hacky, so use at your own risk.

However, anyone is welcome to use them, and I'm happy to answer questions about them.

License and Copyright
-------
Licensed under [GNU General Public License (GPL)](http://www.gnu.org/licenses/gpl.txt), version 3 or later.

Copyright (C) 2015 Dawn M. Foster

Usage
-------
Assumes that you have already used mlstats or CVSAnaly to populate one or more MySQL databases. Most people will 
have one mlstats database; however, since I'm looking at over a decade of Linux kernel mailing list posts, I've 
decided to use a separate database for each mailing list.

Read the comments at the top of each script for documentation about using the scripts. There are expected
arguments and other requirements and expected file configuration, etc.

For mlstats scripts:

* Run thread_replies.sh for each person you are interested in and for each mlstats database.
This means that you might run this script several times for each person.
* I take the final output file and import it into LibreOffice to make it easier to read and 
Sometimes need to do some manual clean-up.
* If I have people using multiple email addresses, I export it into a comma separated CSV and 
then run it through de-dup-email.sh
* I take this comma separated de-dupped file and run add_timezone.sh, since I forgot to add
time zones to the original query.

For CVSAnaly scripts:

* Run files_committed.sh to get a list of files committed by specific people. It takes as input
a list of email addresses. There are two versions of this script - with an without filenames and 
filepaths. See the comments at the top of the with filepaths version for explanation.
* Use collab_file_commits.sh to find all of the people who are collaborating on the same files.
It takes output from either files_committed script as input. WARNING: this can generate a massive
amount of data for people who have edited a lot of files or contributed to frequently edited files.


