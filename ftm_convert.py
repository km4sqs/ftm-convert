#!/usr/bin/python
# ftm_convert.py
versionmsg = 'v1.0.2'
# Written by: Joseph Botto - KM4SQS (km4sqs@gmail.com)
# Written on: 10-27-2017 
# Ported to Python on: 08-27-2018
# Purpose: Script to convert a CHIRP .csv to an ADMS-9 .csv, to import into ADMS-9 
#          for the Yaesu FTM-100DR/FTM-100DE.
#
#
# This program is free software: you can redistribute it and/or modify it under the 
# terms of the GNU General Public License as published by the Free Software 
# Foundation, either version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY 
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this 
# program. If not, see http://www.gnu.org/licenses/.
#
#
# Changelog
# 08-27-2018: v1.0.2 - Ported script to Python
# 11-01-2017: v1.0.1 - Fixed a typo: tr_offsetamount, NOT tr_setamount! DOH!
# 10-27-2017: v1.0.0 - Initial release
#

# Colors class borrowed from:  https://stackoverflow.com/a/287944

# Import modules

import os.path
import argparse
import csv


class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

# First: let's set-up our command line options:

parser = argparse.ArgumentParser(description='Script to convert a CHIRP .csv to an ADMS-9 .csv, to import into ADMS-9 for the Yaesu FTM-100DR/FTM-100DE.')
parser.add_argument('inputfile', action='store', type=str, help='the full path to the CHIRP input .csv file')
parser.add_argument('outputfile', action='store', type=str, help='the full path to the ADMS-9 output .csv file')
parser.add_argument('membank', action='store', choices=['a','b'], help='the memory bank the full path to the ADMS-9 output .csv file (a or b)')

args =  parser.parse_args()

if args.membank == 'a':
    memrows="0,,0"
else:
    memrows="0,,1"

# Check to see that the input file exists

if os.path.isfile(args.inputfile) != True:
    print bcolors.FAIL + "\nInput file " + args.inputfile + " does not exist: Check your path and try again!\n\nExiting!!\n\n"
    exit()

rowcount = 0

# First: let's open the output file:
outputfile = open(args.outputfile, "a")


# Next: Let's read-in our csv, shall we?
with open(args.inputfile) as csvfile:
    reader = csv.DictReader(csvfile, delimiter=',')
    for row in reader:
        rowcount += 1
        location = row['Location']
        name = row['Name']
        initrx = format(float(row['Frequency']), '.5f')
        offsetdir = row['Duplex']
        offsetamount = format(float(row['Offset']), '.5f')
        inittone = row['Tone']
        tonefreq = format(float(row['rToneFreq']), '.1f')
        
        # Lets see what our init frequency is, and set stepping accordingly:
        if str(initrx[0][0]) == "1":
            step = "15.0KHz"
        else:
            step = "25.0KHz"
        
        # Now: lets make our floats 5 digits, not 6, so ADMS-9 doesn't freak out!
        rxfreq = initrx

        # Now: lets calculate our offsets, and set them correctly!
        
        if offsetdir == "+":
            txfreq = float(initrx) + float(offsetamount)
            offsetdir = "+RPT"
        elif offsetdir == "-":
            txfreq = float(initrx) - float(offsetamount)
            offsetdir = "-RPT"
        else: 
            offsetamount = float(0.00000)
            txfreq = float(initrx)
            offsetdir = "OFF"


        # Now: lets set tone encoding type!

        if "Tone" in inittone:
            tonetype = "TONE ENC"
        else:
            tonetype = "OFF"

        # And finally: let's write all this stuff to the output file!
        outputfile.write("%s,%.5f,%.5f,%.5f,%s,FM,%s,%s,%.1f Hz,023,1500 Hz,HIGH,OFF,%s,%s\n" % (str(location), float(rxfreq), float(txfreq), float(offsetamount), str(offsetdir), str(name), str(tonetype), float(tonefreq), str(step), str(memrows)))

rowsleft = int("500") - int(rowcount)


while rowcount < 501:
    out_to_write = "%d,,,,,,,,,,,,,,%s" % (rowcount, str(memrows))
    outputfile.write(out_to_write+'\n')
    rowcount += 1


outputfile.close()
