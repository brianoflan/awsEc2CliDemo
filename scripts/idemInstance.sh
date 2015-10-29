#!/bin/bash

# # # USAGE:
# # #  idemInstance.sh $vpcId $subnetId $secGrpId $keyPairName $ec2_ami $instancePrivateIp $trueFalseAssociatePublicIpAddress
# # #                  $1     $2        $3        $4           $5       $6                 $7

defaultDoAssociatePublicIp='false' ;

if [[ -z $INSTANCE_TYPE ]] ; then
  export INSTANCE_TYPE=t2.micro ;
fi ;

if [[ -z $1 ]] ; then
  if [[ -z $vpcId ]] ; then
    echo "ERROR:  Inadequate args"'!' 1>&2 ;
    echo " Usage:  idemInstance.sh \$vpcId \$subnetId \$secGrpId \$keyPairName \$ec2_ami \$instancePrivateIp \$trueFalseAssociatePublicIpAddress" 1>&2 ;
    exit 1 ;
  fi ;
else
  export vpcId=$1 ;
fi ;

if [[ -z $2 ]] ; then
  if [[ -z $subnetId ]] ; then
    echo "ERROR:  Inadequate args"'!' 1>&2 ;
    echo " Usage:  idemInstance.sh \$vpcId \$subnetId \$secGrpId \$keyPairName \$ec2_ami \$instancePrivateIp \$trueFalseAssociatePublicIpAddress" 1>&2 ;
    exit 1 ;
  fi ;
else
  export subnetId=$2 ;
fi ;

if [[ -z $3 ]] ; then
  if [[ -z $secGrpId ]] ; then
    echo "ERROR:  Inadequate args"'!' 1>&2 ;
    echo " Usage:  idemInstance.sh \$vpcId \$subnetId \$secGrpId \$keyPairName \$ec2_ami \$instancePrivateIp \$trueFalseAssociatePublicIpAddress" 1>&2 ;
    exit 1 ;
  fi ;
else
  export secGrpId=$3 ;
fi ;

if [[ -z $4 ]] ; then
  if [[ -z $keyPairName ]] ; then
    echo "ERROR:  Inadequate args"'!' 1>&2 ;
    echo " Usage:  idemInstance.sh \$vpcId \$subnetId \$secGrpId \$keyPairName \$ec2_ami \$instancePrivateIp \$trueFalseAssociatePublicIpAddress" 1>&2 ;
    exit 1 ;
  fi ;
else
  export keyPairName=$4 ;
fi ;

if [[ -z $5 ]] ; then
  if [[ -z $ec2_ami ]] ; then
    echo "ERROR:  Inadequate args"'!' 1>&2 ;
    echo " Usage:  idemInstance.sh \$vpcId \$subnetId \$secGrpId \$keyPairName \$ec2_ami \$instancePrivateIp \$trueFalseAssociatePublicIpAddress" 1>&2 ;
    exit 1 ;
  fi ;
else
  export ec2_ami=$5 ;
fi ;

if [[ -z $6 ]] ; then
  if [[ -z $instancePrivateIp ]] ; then
    echo "ERROR:  Inadequate args"'!' 1>&2 ;
    echo " Usage:  idemInstance.sh \$vpcId \$subnetId \$secGrpId \$keyPairName \$ec2_ami \$instancePrivateIp \$trueFalseAssociatePublicIpAddress" 1>&2 ;
    exit 1 ;
  fi ;
else
  export instancePrivateIp=$6 ;
fi ;

if [[ -z $7 ]] ; then
  if [[ -z $trueFalseAssociatePublicIpAddress ]] ; then
    export trueFalseAssociatePublicIpAddress="$defaultDoAssociatePublicIp"
  fi ;
else
  export trueFalseAssociatePublicIpAddress=$7 ;
fi ;


if [[ -z $DO_CLEAN ]] ; then
  export DO_CLEAN="false" ;
fi ;
if [[ -z $BUILD_DIR ]] ; then
  export BUILD_DIR=${thisDir}/build ;
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

# # http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-DescribeInstances.html
# # http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-RunInstances.html
# alreadyInstance=`ec2-describe-instances -F "vpc-id=$vpcId" -F "subnet-id=$subnetId" ` ;
alreadyInstance=`ec2-describe-instances -F "vpc-id=$vpcId" -F "subnet-id=$subnetId" -F "private-ip-address=$instancePrivateIp" ` ;
if [[ $alreadyInstance ]] ; then
  echo "Already an instance." ;
else
  cmdX="ec2-run-instances $ec2_ami -k $keyPairName -g $secGrpId \
    -t $INSTANCE_TYPE -s $subnetId --private-ip-address $instancePrivateIp \
    --associate-public-ip-address $trueFalseAssociatePublicIpAddress
    " ;
  true ;
  echo "Cmd: $cmdX" ;
  error='' ;
  alreadyInstance=`$cmdX` ; error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "Error (non-zero exit code) from command: '$error'." ;
  fi ;
fi ;
echo "  DEBUG: Instance = {$alreadyInstance}." 1>&2 ;
instanceId=`echo $alreadyInstance | perl -ne '/(^|\s)INSTANCE\s+(i[\-]\S+)(\s|$)/ && print $2' ` ;
echo "  DEBUG: Instance ID = {$instanceId}." 1>&2 ;
echo "$instanceId" ;


#

exit 0 ;

#
