#!/bin/bash

# # # USAGE:
# # #  getExtIp.sh $vpcId $instanceId_or_IP

tmp="../build/tmp" ;
if [[ $1 ]] ; then
  export vpcId=$1 ;
else
  if [[ -z $vpcId ]] ; then
    f=$tmp/vpcId ;
    if [[ -f $f ]] ; then
      export vpcId=`cat $f` ;
    fi ;
  fi ;
  if [[ -z $vpcId ]] ; then
    echo "ERROR: Missing first argument \$vpcId." ;
    exit 1 ;
  fi ;
fi ;
if [[ $2 ]] ; then
  instanceId_or_IP=$2 ;
else
    echo "ERROR: Missing second argument \$instanceId_or_IP." ;
    exit 1 ;
fi ;

getExtIpTmp=`echo $instanceId_or_IP | egrep '[.]' ` ;
if [[ $getExtIpTmp ]] ; then
  export getExtIp_internalIp=$instanceId_or_IP ;
  # cmdArg="-F \"private-ip-address=$getExtIp_internalIp\"" ;
else
  export getExtIp_instanceId=$instanceId_or_IP ;
fi ;

if [[ $getExtIp_internalIp ]] ; then
  # already=`ec2-describe-instances -H --show-empty-fields -F "vpc-id=$vpcId" -F "private-ip-address=$getExtIp_internalIp" ` ;
  already=`ec2-describe-instances -F "vpc-id=$vpcId" -F "private-ip-address=$getExtIp_internalIp" ` ;
else
  already=`ec2-describe-instances "$getExtIp_instanceId" ` ;
fi ;

echo -e "raw output = " 1>&2 ;
echo "$already" | perl -ne 'print "  $_" ' 1>&2 ;
echo 1>&2 ;

extIp=`echo "$already" | egrep '^NICASSOCIATION' | awk '{print $2}' ` ;
echo "$extIp" ;

#
