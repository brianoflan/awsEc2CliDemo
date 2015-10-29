#!/bin/bash

# # # USAGE:
# # #  idemVpc.sh $filterName $filterValue
# # #   (filter is usually 'cidr')

if [[ -z $1 ]] ; then
  echo "ERROR:  No args"'!' ;
  echo " Usage:  idemVpc.sh \$filterName \$filterValue" ;
  echo "  (filter is usually 'cidr')" ;
  echo "  (filter is usually 'cidr')" ;
  exit 1 ;
fi ;

if [[ -z $2 ]] ; then
  echo "WARNING:  No filter name.  Assuming 'cidr' (set to arg '$1')." ;
  filterName='cidr' ;
  vpcCidr=$1 ;
else
  filterName=$1 ;
  vpcCidr=$2 ;
fi ;

tmp=$BUILD_DIR/tmp ;
if [[ ! -d $tmp ]] ; then
  mkdir $tmp ;
fi ;

# # http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-RunInstances.html
# alreadyVpc=`ec2-describe-vpcs -F "cidr=$vpcCidr" ` ;
# alreadyVpc=`execute ec2-describe-vpcs -F "cidr=$vpcCidr" ` ;
# execute alreadyVpc=`ec2-describe-vpcs -F "cidr=$vpcCidr" ` ;
# execute ec2-describe-vpcs -F "cidr=$vpcCidr" > $tmp/vpcs ;
execute ec2-describe-vpcs -F "$filterName=$vpcCidr" > $tmp/vpcs ;
alreadyVpc=`cat $tmp/vpcs` ;
if [[ $alreadyVpc ]] ; then
  echo "Already a VPC." ;
else
  cmdX="ec2-create-vpc $vpcCidr" ;
  echo "Cmd: $cmdX" ;
  error='' ;
  alreadyVpc=`$cmdX` ; error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "Error (non-zero exit code) from command: '$error'." ;
  fi ;
  sleep 60 ;
fi ;
echo "  DEBUG: VPC = {$alreadyVpc}."
vpcId=`echo $alreadyVpc | perl -ne '/(^|\s)(vpc[\-]\S+)(\s|$)/ && print $2' ` ;
echo "  DEBUG: VPC ID = {$vpcId}."

#
