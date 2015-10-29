#!/bin/bash

# # http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ec2-cli-launch-instance.html
# # Valuable but less official: https://www.linux.com/learn/tutorials/761430-an-introduction-to-the-aws-command-line-tool

if [[ -z $secGrpRule_useExclusiveIp ]] ; then
  $secGrpRule_useExclusiveIp='1' ;
fi ;
if [[ -z $instancePrivateIp ]] ; then
  instancePrivateIp='12.3.4.5' ;
fi ;
if [[ -z $vpcCidr ]] ; then
  export vpcCidr='12.3.0.0/16' ;
fi ;
if [[ -z $subnetCidr ]] ; then
  # subnetCidr='12.3.128.0/17' ;
  export subnetCidr='12.3.0.0/17' ;
fi ;
if [[ -z $subnetCidr ]] ; then
  export subnetCidr=$vpcCidr ;
fi ;
if [[ -z $keyPairName ]] ; then
  keyPairName='cliDemo1_keyPair1'
fi ;
if [[ -z $secGrpDesc ]] ; then
  secGrpDesc="Basic Security Group for Amazon EC2 demo 1." ;
fi ;

if [[ -z $DO_CLEAN ]] ; then
  export DO_CLEAN="false" ;
fi ;

if [[ -z $USE_EC2_AMI ]] ; then
  # # export USE_EC2_AMI=ami-cf1066aa ; # us-east-1 region ?
  export USE_EC2_AMI=ami-cb3aff8f ;
fi ;

if [[ -z $INSTANCE_TYPE ]] ; then
  export INSTANCE_TYPE=t2.micro ;
fi ;

if [[ -z $USE_THIS_SEC_GRP ]] ; then
  export USE_THIS_SEC_GRP=cliDemoSG1 ;
fi ;

if [[ -z $BUILD_DIR ]] ; then
  export BUILD_DIR=${thisDir}/build ;
fi ;

tmp=$BUILD_DIR/tmp ;
f=$tmp/awsEc2SecGroups.txt ;
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


# # # MAIN

echo > $BUILD_DIR/source_me.sh ;
for x in AWS_ACCESS_KEY AWS_SECRET_KEY EC2_HOME EC2_URL JAVA_HOME PATH CLASSPATH ; do
  eval "echo \"$x=$$x\"" >> $BUILD_DIR/source_me.sh ;
done ;

# if [[ '1' ]] ; then
  execute $thisDir/idemVpc.sh cidr "$vpcCidr" > $tmp/vpcId ;
  export vpcId=`cat $tmp/vpcId` ;
# fi ;

# if [[ '1' ]] ; then
  # execute $thisDir/idemSubnet.sh "$vpcCidr" "$subnetCidr" > $tmp/subnetId ;
  execute $thisDir/idemSubnet.sh "$vpcId" "$subnetCidr" > $tmp/subnetId ;
  export subnetId=`cat $tmp/subnetId ` ;
# fi ;

# if [[ '1' ]] ; then
  secGrpName=$USE_THIS_SEC_GRP ;
  execute $thisDir/idemSecGrp.sh "$vpcId" "$secGrpName" "$secGrpDesc" > $tmp/secGrpId ;
  export secGrpId=`cat $tmp/secGrpId ` ;
  # echo "Success. secGrpId=$secGrpId" ;
# fi ;

if [[ $secGrpRule_useExclusiveIp ]] ; then
  execute ifconfig > $tmp/ifconfig ;
  myIpv4=`cat $tmp/ifconfig | grep 'inet addr' | grep -v '127\.0\.0\.1' ` ;
  myIpv4=`echo "$myIpv4" | grep Bcast | awk '{print $2}' | awk -F: '{print $2}' | head -1` ;
else
  myIpv4='' ;
fi ;

# if [[ '1' ]] ; then
  execute $thisDir/idemSecGrpRule.sh "$secGrpId" "22" "tcp" "$myIpv4" > $tmp/secGrpRule ;
  export secGrpRuleTmp=`cat $tmp/secGrpRule ` ;
  echo "Success. secGrpRuleTmp=$secGrpRuleTmp" ;
# fi ;

if [[ '1' ]] ; then
  execute $thisDir/findAmi.sh > $tmp/findAmi ;
  export findAmiTmp=`cat $tmp/findAmi ` ;
  echo "Success. findAmiTmp=$findAmiTmp" ;
fi ;
  
  echo "Success." ;
  exit 0 ;

if [[ '1' ]] ; then
  execute $thisDir/idemKeyPair.sh "$keyPairName" > $tmp/keyPair ;
  export keyPairTmp=`cat $tmp/keyPair ` ;
  echo "Success. keyPairTmp=$keyPairTmp" ;
fi ;

# # http://docs.aws.amazon.com/cli/latest/userguide/cli-ec2-keypairs.html
alreadyAKeypair=`ls -d $tmp/keyPairPrivate.pem` ;
if [[ $alreadyAKeypair ]] ; then
  echo "Already have a key pair."
else
  cmdX="ec2-create-keypair $keyPairName" ;
  echo "Cmd: $cmdX" ;
  error='' ;
  $cmdX > $tmp/keyPairOutput.txt ; error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "Error (non-zero exit code) from command." ;
  fi ;
  sed '1d' $tmp/keyPairOutput.txt > $tmp/keyPairPrivate.pem ;
  chmod 400 $tmp/keyPair* ;
fi ;
alreadyAKeypair=`ls -d $tmp/keyPairPrivate.pem` ;
echo "alreadyAKeypair = '$alreadyAKeypair'" ;

# # http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-DescribeInstances.html
# # http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-RunInstances.html
alreadyInstance=`ec2-describe-instances -F "vpc-id=$vpcId" -F "subnet-id=$subnetId" ` ;
if [[ $alreadyInstance ]] ; then
  echo "Already an instance." ;
else
  cmdX="ec2-run-instances $USE_EC2_AMI -k $keyPairName -g $secgrpid \
    -t $INSTANCE_TYPE -s $subnetId --private-ip-address $instancePrivateIp \
    --associate-public-ip-address true
    " ;
  true ;
  echo "Cmd: $cmdX" ;
  error='' ;
  alreadyInstance=`$cmdX` ; error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "Error (non-zero exit code) from command: '$error'." ;
  fi ;
fi ;
echo "  DEBUG: Instance = {$alreadyInstance}."
instanceId=`echo $alreadyInstance | perl -ne '/(^|\s)INSTANCE\s+(i[\-]\S+)(\s|$)/ && print $2' ` ;
echo "  DEBUG: Instance ID = {$instanceId}."

# 

echo "Done."

#
