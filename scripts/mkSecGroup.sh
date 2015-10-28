#!/bin/bash

# # http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ec2-cli-launch-instance.html
# # Valuable but less official: https://www.linux.com/learn/tutorials/761430-an-introduction-to-the-aws-command-line-tool

instancePrivateIp='12.3.4.5' ;
vpcCidr='12.3.0.0/16' ;
# vpcSubnetCidr='12.3.128.0/17' ;
vpcSubnetCidr='12.3.0.0/17' ;
keyPairName='cliDemo1_keyPair1'
groupDesc="Basic Security Group for Amazon EC2 demo 1." ;

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

if [[ ! -d $tmp ]] ; then
  mkdir $tmp ;
fi ;

# # # MAIN

# # http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-RunInstances.html
# if [[ '1' ]] ; then
alreadyVpc=`ec2-describe-vpcs -F "cidr=$vpcCidr" ` ;
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

# # http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-DescribeSubnets.html
# # http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-CreateSubnet.html
alreadySubnet=`ec2-describe-subnets -F "vpc-id=$vpcId" -F "cidrBlock=$vpcSubnetCidr" ` ;
if [[ $alreadySubnet ]] ; then
  echo "Already a subnet." ;
else
  cmdX="ec2-create-subnet -c $vpcId -i $vpcSubnetCidr" ;
  echo "Cmd: $cmdX" ;
  error='' ;
  alreadySubnet=`$cmdX` ; error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "Error (non-zero exit code) from command: '$error'." ;
  fi ;
  sleep 60 ;
fi ;
echo "  DEBUG: Subnet = {$alreadySubnet}."
subnetId=`echo $alreadySubnet | perl -ne '/(^|\s)(subnet[\-]\S+)(\s|$)/ && print $2' ` ;
echo "  DEBUG: Subnet ID = {$subnetId}."

# # http://docs.aws.amazon.com/cli/latest/userguide/cli-ec2-sg.html
# aws ec2 describe-security-groups --group-names $USE_THIS_SEC_GRP
# http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-DescribeSecurityGroups.html
ec2-describe-group -F "vpc-id=$vpcId" > $f ;
echo "Debug the list of groups:";
# egrep '^GROUP' $f | awk '{print $2 "" $3}' ;
egrep '^GROUP' $f ;
egrep '^GROUP' $f | awk -F $'\t' '{print $2 " " $4}' ;
echo ;
alreadyExists=$(egrep '^GROUP' $f | awk '{print $2 " " $4}' | perl -ne "/\\Q$USE_THIS_SEC_GRP\\E/ && print $_" ) ;
echo "alreadyExists: q{$alreadyExists}"

if [[ -z $alreadyExists ]] ; then
  echo "Creating group $USE_THIS_SEC_GRP" ;
  tmpO=`ec2-create-group $USE_THIS_SEC_GRP -d "$groupDesc" -c $vpcId && echo $? ` ;
  echo "tmp0: q{$tmpO}" ;
  # alreadyExists=$(echo "$tmp0" | awk '{print $2 "" $3}' | perl -ne "/\\Q$USE_THIS_SEC_GRP\\E/ && print $_" ) ;
  alreadyExists="$tmp0" ;
else
  echo "Already exists."
fi ;

# export secgrpid=`echo "$alreadyExists" | awk '{print $1}'` ;
export secgrpid=`echo "$alreadyExists" | perl -ne '/(^|\s)(sg[\-]\S+)(\s|$)/ && print $2' ` ;
echo "secgrpid = '$secgrpid'" ;
if [[ -z $secgrpid ]] ; then
  echo "ERROR: Failed to determine security group id." 1>&2 ;
  exit 1 ;
fi ;

myIpv4=`ifconfig | grep 'inet addr' | grep -v '127\.0\.0\.1' | grep Bcast | awk '{print $2}' | awk -F: '{print $2}' | head -1` ;

cat $f | perl $thisDir/listRules.pl > $tmp/sgRules.txt 2> $tmp/sgRules.err ;

# alreadyARule=`cat $tmp/sgRules.txt | grep ingress | egrep "ALLOWS[ \t][ \t]*tcp[ \t]22[ \t]" ` ;
alreadyARule=`cat $tmp/sgRules.txt | grep ingress | perl -ne '/ALLOWS\s+tcp\s+22\s/ && print $_' ` ;
if [[ $alreadyARule ]] ; then
  echo "TCP 22 is already a rule."
else
  cmdX="ec2-authorize $USE_THIS_SEC_GRP -P tcp -p 22 -s ${myIpv4}/24" ;
  echo "Cmd: $cmdX" ;
  error='' ;
  $cmdX ; error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "Error (non-zero exit code) from command." ;
  fi ;
fi ;

if [[ '1' ]] ; then
  # cmdX="ec2-describe-images -a -o amazon --filter \"is-public=true\" -F \"architecture=x86_64\" --filter \"platform=linux\" " ;
  # cmdX="ec2-describe-images -o amazon --filter \"is-public=true\" -F \"architecture=x86_64\" --filter \"platform=linux\" " ;
  #   -F \"root-device-type=instance-store\" \
  #   -F \"virtualization-type=paravirtual\" \
  cmdX="ec2-describe-images -o amazon -F \"is-public=true\" -F \"image-type=machine\" \
    -F \"architecture=x86_64\" \
    -F \"virtualization-type=hvm\" \
    -F \"root-device-type=ebs\" \
    " ;
  true ;
  echo "Cmd: $cmdX" ;
  error='' ;
  $cmdX | egrep -vi '(BLOCKDEVICEMAPPING|elasticbeanstalk|minimal|suse|windows)' | egrep '2015[\-]09' > $tmp/images.txt ; error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "Error (non-zero exit code) from command." ;
  fi ;
  cat $tmp/images.txt ;
  cat $tmp/images.txt | wc -l ;
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
