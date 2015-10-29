#!/bin/bash

# # # USAGE:
# # #  idemVpc.sh $filterName $filterValue
# # #   (filter is usually 'cidr')

if [[ -z $1 ]] ; then
  echo "ERROR:  No args"'!' 1>&2 ;
  echo " Usage:  idemVpc.sh \$filterName \$filterValue" 1>&2 ;
  echo "  (filter is usually 'cidr')" 1>&2 ;
  exit 1 ;
fi ;

if [[ -z $2 ]] ; then
  echo "WARNING:  No filter name.  Assuming 'cidr' (set to arg '$1')." 1>&2 ;
  filterName='cidr' ;
  vpcCidr=$1 ;
else
  filterName=$1 ;
  vpcCidr=$2 ;
fi ;

if [[ -z $DO_CLEAN ]] ; then
  export DO_CLEAN="false" ;
fi ;
if [[ -z $BUILD_DIR ]] ; then
  export BUILD_DIR="build" ;
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


# # http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-RunInstances.html
# alreadyVpc=`ec2-describe-vpcs -F "cidr=$vpcCidr" ` ;
# alreadyVpc=`execute ec2-describe-vpcs -F "cidr=$vpcCidr" ` ;
# execute alreadyVpc=`ec2-describe-vpcs -F "cidr=$vpcCidr" ` ;
# execute ec2-describe-vpcs -F "cidr=$vpcCidr" > $tmp/vpcs ;
execute ec2-describe-vpcs -F "$filterName=$vpcCidr" > $tmp/vpcs ;
alreadyVpc=`cat $tmp/vpcs` ;
if [[ $alreadyVpc ]] ; then
  echo "Already a VPC." 1>&2 ;
else
  cmdX="ec2-create-vpc $vpcCidr" ;
  echo "Cmd: $cmdX" 1>&2 ;
  error='' ;
  alreadyVpc=`$cmdX` ; error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "Error (non-zero exit code) from command: '$error'." 1>&2 ;
    exit $error ;
  fi ;
  sleep 60 ;
fi ;
echo "  DEBUG: VPC = {$alreadyVpc}." 1>&2 ;
vpcId=`echo $alreadyVpc | perl -ne '/(^|\s)(vpc[\-]\S+)(\s|$)/ && print $2' ` ;
echo "  DEBUG: VPC ID = {$vpcId}." 1>&2 ;
echo "$vpcId" ;

#
