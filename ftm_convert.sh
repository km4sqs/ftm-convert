#!/bin/bash
# ftm_convert
versionmsg="v1.0.1"
# Written by: Joseph Botto - KM4SQS (km4sqs@gmail.com)
# Written on: 10-27-2017 
# Purpose: Script to convert a CHIRP .csv to an ADMS-9 .csv, to inport into ADMS-9 
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
# 11-01-2017: v1.0.1 - Fixed a typo: tr_offsetamount, NOT tr_setamount! DOH!
# 10-27-2017: v1.0   - Initial release
#

# Set some tput colors
F_BLACK="tput setaf 0"
F_RED="tput setaf 1"
F_GREEN="tput setaf 2"
F_YELLOW="tput setaf 3"
F_BLUE="tput setaf 4"
F_MAGENTA="tput setaf 5"
F_CYAN="tput setaf 6"
F_WHITE="tput setaf 7"

B_BLACK="tput setab 0"
B_RED="tput setab 1"
B_GREEN="tput setab 2"
B_YELLOW="tput setab 3"
B_BLUE="tput setab 4"
B_MAGENTA="tput setab 5"
B_CYAN="tput setab 6"
F_WHITE="tput setaf 7"

RESET_COLORS="tput sgr0"


# Function definitions, so we can clean this up a bit!

function error_out() {

# Takes in a command-line variable as input, and makes a nice error message.
    echo -e "\n$($F_RED)$1$($RESET_COLORS)\n"
    echo -e "$($F_RED)Exiting without doing anything! $($RESET_COLORS)\n\n"
    echo -e "$($F_GREEN)$usage\n"
    exit 1
}


# Main Program

usage="\n\n"
usage+="Usage: ftm_convert.sh [options] \n"
usage+="$versionmsg\n\n"
usage+="Description: \n"
usage+="  Script to convert a CHIRP .csv to an ADMS-9 .csv, to inport into ADMS-9\n"
usage+="  .csv format, for the Yaesu FTM-100DR/FTM-100DE.\n"
usage+=" \n\n"
usage+="Options:\n"
usage+="  -h or -help:         print this help\n"
usage+="  -i [file path]:      full path to the input file (CHIRP .csv)\n"
usage+="  -o [file path]:      full path to the output file (ADMS-9 .csv)\n"
usage+="  -b [a or b]:         memory bank for csv (bank a or bank b)\n"
usage+=" \n\n"
usage+="Example: ./ftm_convert.sh -i chirp.csv -o adms-9.csv -b a\n"
usage+=" \n\n"

while getopts :i:o:b:h opt; do
  case $opt in
    h|help)
      echo -e $usage
      exit 0
      ;;

    i)
      inputfile=$OPTARG
      ;;

    o)
      outputfile=$OPTARG
      ;;

    b)
      tempbank=$OPTARG
      ;;

    h)
      echo -e $usage
      exit 0
      ;;

    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;

  esac
done

# Check to see if we have the right number of arguments. If not, exit! 

if [[ "$#" -ne "6" ]]
then
  error_out "Incorrect number of arguments provided!\n"
fi


# Stage our inputs, create a temp file holder, and an output file name
tempinput=$(mktemp)

# Now, let's do some awk-foo to convert the CHIRP format into ADMS-9 layout/format (specifically,
# 5 decimal places on floating point numbers, and column layout.Also, going to cut the header 
# line out of the CHIRP file, as ADMS-9 doesn't like that.

awk '{
FS=",";
#OFMT="%4.5g";
OFS=","

location=$1
name=$2
initrx=$3
offsetdir=$4
offsetamount=$5
inittone=$6
tonefreq=$7
mode=$11

if (substr(initrx,1,1) ~ /^[1]/ ) {
       step="15.0KHz" 
}
else {
       step="25.0KHz" 
}


rxfreq=sprintf("%.5f",initrx);
tr_offsetamount=sprintf("%.5f",offsetamount);

if ( offsetdir ~ "+" ) {
        inittx = initrx + tr_offsetamount ;
        offsetdir = offsetdir"RPT";
}
else if ( offsetdir ~ "-" ) {
        inittx = initrx - tr_offsetamount ;
        offsetdir = offsetdir"RPT";
}
else {
        inittx = rxfreq ;
        offsetdir = "OFF";
}

if ( tr_offsetamount != "5.00000" && tr_offsetamount != "0.60000" ) {
	tr_offsetamount = "0.00000"
}


txfreq=sprintf("%.5f",inittx);


if ( inittone ~ "Tone" ) tonetype = "TONE ENC" ;
else tonetype = "OFF";

printf location","rxfreq","txfreq","tr_offsetamount","offsetdir",FM,"name","tonetype","tonefreq" Hz,023,1500 Hz,HIGH,OFF,"step",0,," "\n";
}' $inputfile | tail -n +2 > $tempinput

# Now, since ADMS-9 wants a 500-line CSV file (even in all of the lines are blank), lets 
# add-in a bunch of blank lines. YAY!

linecounter=$(cat $tempinput | wc -l)
linecounter=$(( $linecounter + 1 ))

while [[ "$linecounter" -le "500" ]]
do
  printf "$linecounter,,,,,,,,,,,,,,0,,\n" >> $tempinput
  linecounter=$(( $linecounter + 1 ))
done

# Now, lets add in either 0 for bank A, or 1 for bank b

bank=$(echo "$tempbank" | awk '{print tolower($0)}')

if [[ "$bank" == "a" ]]
then
  sed -i 's/$/0/' $tempinput
elif [[ "$bank" == "b" ]]
then
  sed -i 's/$/1/' $tempinput
else
  error_out "Incorrect memory bank specified! Please specify either a or b"
fi

mv $tempinput $outputfile

