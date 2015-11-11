#!/bin/bash

# # # USAGE:
# # #  idemInetGWay.sh $vpcId $subnetCidr $optionalNameForGateway

defaultIGwayName="vpcInetGWay1" ;

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
  echo " Usage:  idemInetGWay.sh \$vpcId \$subnetCidr" 1>&2 ;
  exit 1 ;
fi ;
if [[ -n $3 ]] ; then
  export inetGWayName="$3" ;
else
  export inetGWayName="$defaultIGwayName" ;
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

# # http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-DescribeInternetGateways.html
execute ec2-describe-internet-gateways -F "tag:Name=$inetGWayName" > $tmp/inetGWay ;
already=`cat $tmp/inetGWay ` ;
if [[ -z $already ]] ; then
  execute ec2-describe-internet-gateways -F "attachment.vpc-id=$vpcId" > $tmp/inetGWay ;
  already=`cat $tmp/inetGWay ` ;
else
  echo "already = q(${already})" 1>&2 ;
fi ;
if [[ $already ]] ; then
  echo "Already a subnet." 1>&2 ;
# if [[ -z $already ]] ; then
else
  echo "No such internet gateway." 1>&2 ;
  echo "Creating it." 1>&2 ;
  
  cmdX="ec2-create-internet-gateway" ;
  echo "Cmd: $cmdX" 1>&2 ;
  error='' ;
  already=`$cmdX` ; error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "Error (non-zero exit code) from command: '$error'." 1>&2 ;
    exit $error ;
  fi ;
  inetGWayId=`echo $already | perl -ne '/(^|\s)INTERNETGATEWAY\s+(\S+)(\s|$)/ && print $2' ` ;
  echo "inetGWayId: $inetGWayId" 1>&2 ;

  cmdX="ec2-create-tags $inetGWayId --tag Name=$inetGWayName" ;
  echo "Cmd: $cmdX" 1>&2 ;
  error='' ;
  already=`$cmdX` ; error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "Error (non-zero exit code) from command: '$error'." 1>&2 ;
    # # # exit $error ; # Don't actually exit.  Who cares.
  fi ;
  
  cmdX="ec2-attach-internet-gateway $inetGWayId -c $vpcId" ;
  echo "Cmd: $cmdX" 1>&2 ;
  error='' ;
  already=`$cmdX` ; error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "Error (non-zero exit code) from command: '$error'." 1>&2 ;
    exit $error ;
  fi ;

fi ;

echo "already = q(${already})" 1>&2 ;

echo "$inetGWayId" ;


#
