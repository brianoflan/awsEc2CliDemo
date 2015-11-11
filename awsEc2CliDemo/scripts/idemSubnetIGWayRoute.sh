#!/bin/bash

# # # USAGE:
# # #  idemSubnetIGWayRoute.sh $vpcId $inetGWayId

# defaultIGwayName="vpcInetGWay1" ;
destination="0.0.0.0/0" ;

if [[ -z $2 ]] ; then
  if [[ -n $1 ]] ; then
    if [[ -n $vpcId || -n $inetGWayId ]] ; then
      if [[ $vpcId ]] ; then
        export inetGWayId=$1 ;
      else
        if [[ $inetGWayId ]] ; then
          export vpcId=$1 ;
        fi ;
      fi ;
    fi ;
  fi ;
else # If -n $2
  # if [[ -n $1 ]] ; then
    export vpcId=$1 ;
    export inetGWayId=$2 ;
  # fi ;
fi ;
if [[ -z $vpcId || -z $inetGWayId ]] ; then
  echo "ERROR:  Inadequate args"'!' 1>&2 ;
  echo " Usage:  idemSubnetIGWayRoute.sh \$vpcId \$inetGWayId" 1>&2 ;
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

# # http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-DescribeInternetGateways.html
execute ec2-describe-route-tables -F "vpc-id=$vpcId" > $tmp/routeTable ;
already=`cat $tmp/routeTable ` ;
if [[ $already ]] ; then
  echo "Already a route table." 1>&2 ;
# if [[ -z $already ]] ; then
else
  echo "No such route table associated with VPC $vpcId (increase the sleep?)." 1>&2 
  exit 1 ;
fi ;
routeTableId=`echo $already | perl -ne '/(^|\s)ROUTETABLE\s+(\S+)(\s|$)/ && print $2' ` ;
echo "routeTableId: $routeTableId" 1>&2 ;

# if [[ '1' ]] ; then
  cmdX="ec2-create-route $routeTableId -r \"${destination}\" -g \"${inetGWayId}\"" ;
  echo "Cmd: $cmdX" 1>&2 ;
  error='' ;
  already=`$cmdX` ; error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "Error (non-zero exit code) from command: '$error'." 1>&2 ;
    # # # exit $error ; # Don't actually exit.  Who cares.
  fi ;
# fi ;

echo "already = q(${already})" 1>&2 ;

echo "$inetGWayId" ;


#
