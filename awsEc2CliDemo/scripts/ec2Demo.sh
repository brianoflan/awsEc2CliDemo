#!/bin/bash

# # http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ec2-cli-launch-instance.html
# # Valuable but less official: https://www.linux.com/learn/tutorials/761430-an-introduction-to-the-aws-command-line-tool

# BEGIN NAS
  # nasIp='12.3.4.6' ;
  # nasSecGrp='cliDemoSG_NAS' ;
  nasIp='10.20.30.6' ;
  nasSecGrp='cliDemoSG_NAS' ;
# END NAS
# BEGIN HTTPD
  # webIp='12.3.4.7' ;
  webIp='10.20.30.7' ;
  webSecGrp='cliDemoSG_Web' ;
# END HTTPD

if [[ -z $secGrpRule_useExclusiveIp ]] ; then
  secGrpRule_useExclusiveIp='1' ;
fi ;
if [[ -z $instancePrivateIp ]] ; then
  # instancePrivateIp='12.3.4.5' ;
  instancePrivateIp='10.20.30.5' ;
fi ;
if [[ -z $vpcCidr ]] ; then
  # export vpcCidr='12.3.0.0/16' ;
  export vpcCidr='10.20.30.0/24' ; # Through 255.
fi ;
if [[ -z $subnetCidr ]] ; then
  # subnetCidr='12.3.128.0/17' ;
  # export subnetCidr='12.3.0.0/17' ;
  export subnetCidr='10.20.30.0/25' ; # Through 127.
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
  eval "echo \"export $x=\$$x\"" >> $BUILD_DIR/source_me.sh ;
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
  execute $thisDir/idemInetGWay.sh "$vpcId" "$subnetCidr" > $tmp/inetGWay ;
  export inetGWay=`cat $tmp/inetGWay ` ;
# fi ;

# if [[ '1' ]] ; then
  execute $thisDir/idemIGWayRoute.sh "$vpcId" "$inetGWay" ;
  # export x=`cat $tmp/x ` ;
# fi ;

if [[ $secGrpRule_useExclusiveIp ]] ; then
  execute ifconfig > $tmp/ifconfig ;
  myIpv4=`cat $tmp/ifconfig | grep 'inet addr' | grep -v '127\.0\.0\.1' ` ;
  myIpv4=`echo "$myIpv4" | grep Bcast | awk '{print $2}' | awk -F: '{print $2}' | head -1` ;
else
  myIpv4='' ;
fi ;
echo "Success. myIpv4='$myIpv4'" ;

# if [[ '1' ]] ; then
  secGrpName=$USE_THIS_SEC_GRP ;
  execute $thisDir/idemSecGrp.sh "$vpcId" "$secGrpName" "$secGrpDesc" > $tmp/secGrpId ;
  export secGrpId=`cat $tmp/secGrpId ` ;
  # echo "Success. secGrpId=$secGrpId" ;
# fi ;

  # secGrpDesc="Apache HTTPD Security Group for Amazon EC2 demo 1." ;
  # secGrpName=$webSecGrp ;
  # execute $thisDir/idemSecGrp.sh "$vpcId" "$secGrpName" "$secGrpDesc" > $tmp/secGrpId ;
  # export secGrpIdWeb=`cat $tmp/secGrpId ` ;
  
  secGrpDesc="NAS Security Group for Amazon EC2 demo 1." ;
  secGrpName=$nasSecGrp ;
  execute $thisDir/idemSecGrp.sh "$vpcId" "$secGrpName" "$secGrpDesc" > $tmp/secGrpId ;
  export secGrpIdNas=`cat $tmp/secGrpId ` ;
  
  # # Apache HTTPD:
  # execute $thisDir/idemSecGrpRule.sh "$secGrpIdWeb" "80" "tcp" "$myIpv4" > $tmp/secGrpRule ;

  # SMB/Samba/CIFS:
  execute $thisDir/idemSecGrpRule.sh "$secGrpIdNas" "137" "udp" "$myIpv4" > $tmp/secGrpRule ;
  execute $thisDir/idemSecGrpRule.sh "$secGrpIdNas" "138" "tcp" "$myIpv4" > $tmp/secGrpRule ;
  execute $thisDir/idemSecGrpRule.sh "$secGrpIdNas" "139" "tcp" "$myIpv4" > $tmp/secGrpRule ;
  execute $thisDir/idemSecGrpRule.sh "$secGrpIdNas" "445" "tcp" "$myIpv4" > $tmp/secGrpRule ;
  # NFS:
  execute $thisDir/idemSecGrpRule.sh "$secGrpIdNas" "111" "udp" "$myIpv4" > $tmp/secGrpRule ;
  execute $thisDir/idemSecGrpRule.sh "$secGrpIdNas" "111" "tcp" "$myIpv4" > $tmp/secGrpRule ;
  execute $thisDir/idemSecGrpRule.sh "$secGrpIdNas" "2049" "udp" "$myIpv4" > $tmp/secGrpRule ;
  execute $thisDir/idemSecGrpRule.sh "$secGrpIdNas" "2049" "tcp" "$myIpv4" > $tmp/secGrpRule ;

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

# nasIp='12.3.4.6' ;
# nasSecGrp='cliDemoSG_NAS' ;
  
if [[ '1' ]] ; then
  execute $thisDir/idemKeyPair.sh "$keyPairName" > $tmp/keyPair ;
  export keyPairTmp=`cat $tmp/keyPair ` ;
  echo "Success. keyPairTmp=$keyPairTmp" ;
fi ;

if [[ '1' ]] ; then
  doAssociatePublicIpAddress=true ;
  execute $thisDir/idemInstance.sh "$vpcId" "$subnetId" "$secGrpId" "$keyPairName" "$USE_EC2_AMI" \
    "$instancePrivateIp" "$doAssociatePublicIpAddress" > $tmp/instanceId ;
    #
  #
  export instanceId=`cat $tmp/instanceId ` ;
  echo "Success. instanceId=$instanceId" ;
fi ;

#
  execute $thisDir/idemInstance.sh "$vpcId" "$subnetId" "$secGrpIdNas" "$keyPairName" "$USE_EC2_AMI" \
    "$nasIp" "false" > $tmp/instanceId ;
    #
  #
  export nasInstance=`cat $tmp/instanceId ` ;
#
#
#

echo "Success." ;
exit 0 ;

# 

echo "Done."

#
