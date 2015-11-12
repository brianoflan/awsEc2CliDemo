#!/bin/bash

pwd 1>&2 ;
if [[ -f ../build/tmp/skipDemoScript ]] ; then
  exit 0 ;
fi ;

# # http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ec2-cli-launch-instance.html
# # Valuable but less official: https://www.linux.com/learn/tutorials/761430-an-introduction-to-the-aws-command-line-tool

# BEGIN Chef Server
  # Chef Server 12, free 5 node, https://aws.amazon.com/marketplace/pp/B010OMNV2W, from https://docs.chef.io/aws_marketplace.html
  chefServerAmi='ami-f38346b7' ;
  chefServerIp='10.20.30.8' ;
  chefServerInstType='t2.medium' ;
# END Chef Server

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
  execute $thisDir/idemInetGWay.sh "$vpcId" "$subnetCidr" > $tmp/inetGWayId ;
  export inetGWay=`cat $tmp/inetGWayId ` ;
# fi ;

# if [[ '1' ]] ; then
  execute $thisDir/idemIGWayRoute.sh "$vpcId" "$inetGWay" ;
  # export x=`cat $tmp/x ` ;
# fi ;

if [[ $secGrpRule_useExclusiveIp ]] ; then
  execute ifconfig > $tmp/ifconfig ;
  myIpv4=`cat $tmp/ifconfig | grep 'inet addr' | grep -v '127\.0\.0\.1' ` ;
  myIpv4=`echo "$myIpv4" | grep Bcast | awk '{print $2}' | awk -F: '{print $2}' | head -1` ;
  # # Nope.  Just because that's the IP it presents to ifconfig doesn't mean
  # #  that's what the open waters sees.
  # # http://stackoverflow.com/questions/3097589/getting-my-public-ip-via-api
  myIpv4='' ;
  # execute curl www.telize.com/ip > $tmp/ifconfig ;
  execute curl icanhazip.com > $tmp/ifconfig ;
  myIpv4=`cat $tmp/ifconfig` ;
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
  execute $thisDir/idemSecGrpRule.sh "$secGrpIdNas" "137" "udp" "$myIpv4" "16" > $tmp/secGrpRule ;
  execute $thisDir/idemSecGrpRule.sh "$secGrpIdNas" "138" "tcp" "$myIpv4" "16" > $tmp/secGrpRule ;
  execute $thisDir/idemSecGrpRule.sh "$secGrpIdNas" "139" "tcp" "$myIpv4" "16" > $tmp/secGrpRule ;
  execute $thisDir/idemSecGrpRule.sh "$secGrpIdNas" "445" "tcp" "$myIpv4" "16" > $tmp/secGrpRule ;
  # NFS:
  execute $thisDir/idemSecGrpRule.sh "$secGrpIdNas" "111"  "udp" "$myIpv4" "16" > $tmp/secGrpRule ;
  execute $thisDir/idemSecGrpRule.sh "$secGrpIdNas" "111"  "tcp" "$myIpv4" "16" > $tmp/secGrpRule ;
  execute $thisDir/idemSecGrpRule.sh "$secGrpIdNas" "2049" "udp" "$myIpv4" "16" > $tmp/secGrpRule ;
  execute $thisDir/idemSecGrpRule.sh "$secGrpIdNas" "2049" "tcp" "$myIpv4" "16" > $tmp/secGrpRule ;

# if [[ '1' ]] ; then
  execute $thisDir/idemSecGrpRule.sh "$secGrpId" "22"   "tcp" "$myIpv4" "16" > $tmp/secGrpRule ;
  execute $thisDir/idemSecGrpRule.sh "$secGrpId" "443"  "tcp" "$myIpv4" "16" > $tmp/secGrpRule ;
  execute $thisDir/idemSecGrpRule.sh "$secGrpId" "8443" "tcp" "$myIpv4" "16" > $tmp/secGrpRule ;
  execute $thisDir/idemSecGrpRule.sh "$secGrpId" "5672" "tcp" "$myIpv4" "16" > $tmp/secGrpRule ; # RabbitMQ for Chef Server
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

# NAS
  doAssociatePublicIpAddress=false ;
  execute $thisDir/idemInstance.sh "$vpcId" "$subnetId" "$secGrpIdNas" "$keyPairName" "$USE_EC2_AMI" \
    "$nasIp" "$doAssociatePublicIpAddress" > $tmp/instanceId ;
    #
  #
  export nasInstance=`cat $tmp/instanceId ` ;
  echo "nasInstance = $nasInstance" 1>&2 ;
#

# Chef Server
  secGrpIdChefServer=$secGrpId ;
  doAssociatePublicIpAddress=false ;
  export INSTANCE_TYPE=t2.medium ;
  execute $thisDir/idemInstance.sh "$vpcId" "$subnetId" "$secGrpIdChefServer" "$keyPairName" "$chefServerAmi" \
    "$chefServerIp" "$doAssociatePublicIpAddress" > $tmp/instanceId ;
    #
  #
  export chefServerInstance=`cat $tmp/instanceId ` ;
  echo "chefServerInstance = $chefServerInstance" 1>&2 ;
#

#
#

echo "Success." ;
exit 0 ;

# 

echo "Done."

#
