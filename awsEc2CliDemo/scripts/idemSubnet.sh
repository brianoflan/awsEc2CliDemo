#!/bin/bash

# # # USAGE:
# # #  idemSubnet.sh $vpcId $subnetCidr

if [[ -z $2 ]] ; then
  if [[ -n $1 ]] ; then
    if [[ -n $vpcId || -n $subnetCidr ]] ; then
      if [[ $vpcId ]] ; then
        export subnetCidr=$1 ;
      else
        if [[ $subnetCidr ]] ; then
          export vpcId=$1 ;
        fi ;
      fi ;
    fi ;
  fi ;
else # If -n $2
  # if [[ -n $1 ]] ; then
    export vpcId=$1 ;
    export subnetCidr=$2 ;
  # fi ;
fi ;
if [[ -z $vpcId || -z $subnetCidr ]] ; then
  echo "ERROR:  Inadequate args"'!' 1>&2 ;
  echo " Usage:  idemSubnet.sh \$vpcId \$subnetCidr" 1>&2 ;
  exit 1 ;
fi ;

if [[ -z $DO_CLEAN ]] ; then
  export DO_CLEAN="false" ;
fi ;

tmp=$BUILD_DIR/tmp ;
if [[ "$DO_CLEAN" == "true" ]] ; then
  if [[ -d $tmp ]] ; then
    rm -rf $tmp ;
  fi ;
fi ;
if [[ ! -d $tmp ]] ; then
  mkdir $tmp ;
fi ;


# # # BEGIN thisDir
  thisDir=$(dirname $0) ;
  pwdX=$(pwd) ;
  abs=`dirname $0 | sed -e 's/^\(.\).*$/\1/'` ;
  if [[ -z $thisDir || "$thisDir" == "." ]] ; then
    thisDir="$pwdX" ;
  else
    if [[ "$abs" != "/" ]] ; then
      thisDir="$pwdX/$thisDir" ;
    fi ;
  fi ;
  scriptBase=$(basename $0) ;
  # cd $thisDir ;
# # # END thisDir

# # # BEGIN execute
  if [[ -z $DEBUG ]] ; then
    DEBUG='' ;
  fi ;
  function execute {
    cmdX="$@" ;
    if [[ $DEBUG -gt 0 ]] ; then
      echo "execute $@" 1>&2 ;
    fi ;
    "$@" ;
    error=$? ;
    if [[ -z $error || "$error" == "" || "$error" == "0" ]] ; then
      true ;
    else
      echo "ERROR: From command $cmdX: '$error'." 1>&2 ;
      exit $error ;
    fi ;
  }
# # # END execute


#

# # http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-DescribeSubnets.html
# # http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-CreateSubnet.html
# alreadySubnet=`ec2-describe-subnets -F "vpc-id=$vpcId" -F "cidrBlock=$subnetCidr" ` ;
execute ec2-describe-subnets -F "vpc-id=$vpcId" -F "cidrBlock=$subnetCidr" > $tmp/subnets ;
alreadySubnet=`cat $tmp/subnets ` ;
if [[ $alreadySubnet ]] ; then
  echo "Already a subnet." 1>&2 ;
else
  cmdX="ec2-create-subnet -c $vpcId -i $subnetCidr" ;
  echo "Cmd: $cmdX" 1>&2 ;
  error='' ;
  alreadySubnet=`$cmdX` ; error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "Error (non-zero exit code) from command: '$error'." 1>&2 ;
    exit $error ;
  fi ;
  sleep 60 ;
fi ;
echo "  DEBUG: Subnet = {$alreadySubnet}." 1>&2 ;
subnetId=`echo $alreadySubnet | perl -ne '/(^|\s)(subnet[\-]\S+)(\s|$)/ && print $2' ` ;
echo "  DEBUG: Subnet ID = {$subnetId}." 1>&2 ;
echo "$subnetId" ;


#
