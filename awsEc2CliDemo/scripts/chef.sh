#!/bin/bash

export LC_ALL='en_US.UTF-8' ;

gitDkUrl='https://github.com/chef/chef-dk.git' ;
useUser2=user2 ;
yumInstallList='git ruby-devel make gcc' ;
useUser1='ec2-user' ;
privKey='../AwsEc2KeyPairs.d/cliDemo1_keyPair1.keyPairPrivate' ;
workstationInternalIp='10.20.30.5' ;
tutDemoDir=awsDemoChefTut2 ;
gitRepo="https://github.com/brianoflan/${tutDemoDir}.git" ;
tmp="../build/tmp" ;

# thisdir
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
cd $thisDir ;

# execute
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

#

#

extIp=`/bin/bash $thisDir/getExtIp.sh '' $workstationInternalIp ` ;

error='' ;

if [[ '' ]] ; then
  # ssh -i $thisDir/$privKey $useUser1@$extIp /bin/bash -c "sudo yum install -y git ; git clone $gitRepo" || error=$? ;
  ssh -i $thisDir/$privKey $useUser1@$extIp -t -t sudo yum list installed git 2>&1 \
    | grep git > $thisDir/$tmp/yumListGit || error=$? ;
  #
  if [[ $error -gt 0 ]] ; then
    echo "error='$error'" ;
    exit $error ;
  fi ;
fi ;

# ssh -i $thisDir/$privKey.pem $useUser1@$extIp /bin/bash -c "sudo yum install -y git ; git clone $gitRepo" || error=$? ;
ssh -i $thisDir/$privKey.pem $useUser1@$extIp -t -t sudo yum install -y $yumInstallList 1>&2 || error=$? ;
if [[ $error -gt 0 ]] ; then
  echo "error='$error'" ;
  exit $error ;
fi ;

x=`ssh -i $thisDir/$privKey.pem $useUser1@$extIp ls -d /home/$useUser2 2>/dev/null ` ;
if [[ -z $x ]] ; then
  ssh -i $thisDir/$privKey.pem $useUser1@$extIp -t -t sudo useradd $useUser2 1>&2 || error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "error from useradd='$error'" ;
    exit $error ;
  fi ;
fi ;

madeNewSshFolder='' ;
x=`ssh -i $thisDir/$privKey.pem $useUser1@$extIp -t -t sudo ls -d /home/$useUser2/.ssh 2>/dev/null ` ;
if [[ -z $x ]] ; then
  ssh -i $thisDir/$privKey.pem $useUser1@$extIp -t -t sudo mkdir /home/$useUser2/.ssh 1>&2 || error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "error from mkdir .ssh='$error'" ;
    exit $error ;
  fi ;
  madeNewSshFolder=1 ;
fi ;
  
x=`ssh -i $thisDir/$privKey.pem $useUser1@$extIp -t -t /bin/bash -c "sudo ls -d /home/$useUser2/.ssh/authorized_keys 2>/dev/null" 2>$thisDir/$tmp/existsAuthKeys ` ;
x=`echo "$x" | egrep -v 'bash. warning. setlocale. .+ cannot change locale' ` ;
# if [[ -z $x ]] ; then
if [[ $x ]] ; then
  echo "Weird: $x" ;
  echo "End of weird." ;
else
  # ssh -i $thisDir/$privKey.pem $useUser1@$extIp -t -t /bin/bash -c "sudo echo \"`cat $thisDir/$privKey.pub`\" > /tmp/chef.sh.authorized_keys" 1>&2 || error=$? ;
  scp -i $thisDir/$privKey.pem $thisDir/$privKey.pub $useUser1@$extIp:/tmp/chef.sh.authorized_keys 1>&2 || error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "error from echo into auth keys='$error'" ;
    exit $error ;
  fi ;
  
  ssh -i $thisDir/$privKey.pem $useUser1@$extIp -t -t sudo mv /tmp/chef.sh.authorized_keys /home/$useUser2/.ssh/authorized_keys 1>&2 || error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "error='$error'" ;
    exit $error ;
  fi ;
  
  ssh -i $thisDir/$privKey.pem $useUser1@$extIp -t -t sudo chmod 600 /home/$useUser2/.ssh/authorized_keys 1>&2 || error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "error='$error'" ;
    exit $error ;
  fi ;
  
  ssh -i $thisDir/$privKey.pem $useUser1@$extIp -t -t sudo chown $useUser2 /home/$useUser2/.ssh/authorized_keys 1>&2 || error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "error='$error'" ;
    exit $error ;
  fi ;
  
fi ;
  
if [[ $madeNewSshFolder ]] ; then  
  ssh -i $thisDir/$privKey.pem $useUser1@$extIp -t -t sudo chmod 700 /home/$useUser2/.ssh 1>&2 || error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "error='$error'" ;
    exit $error ;
  fi ;
fi ;

# # # NOW AS USER2

for url in $gitDkUrl $gitRepo ; do
  ssh -i $thisDir/$privKey.pem $useUser2@$extIp git clone $url \
    > $thisDir/$tmp/gitClone 2>&1 || error=$? ;
  if [[ $error -gt 0 ]] ; then
    chefTmp=`cat $thisDir/$tmp/gitClone | grep 'fatal' | grep 'destination path' | grep 'already exists and is not an empty directory' ` ;
    if [[ -z $chefTmp ]] ; then
      echo "maybe okay='$chefTmp'" ;
      echo "error='$error'" ;
      exit $error ;
    fi ;
  fi ;
done ;

ssh -i $thisDir/$privKey.pem $useUser2@$extIp /bin/bash -c "cd chef-dk ; gem install chef-dk" 1>&2 || error=$? ;
if [[ $error -gt 0 ]] ; then
  echo "error with gem install chef-dk='$error'" ;
  # exit $error ;
fi ;

ssh -i $thisDir/$privKey.pem $useUser2@$extIp /bin/bash -c "export PATH=\"/home/$useUser2/chef-dk/bin:\$PATH\" ; cd $tutDemoDir ; pwd ; chef generate cookbook cookbooks/hello_chef_server" 1>&2 || error=$? ;
if [[ $error -gt 0 ]] ; then
  echo "error with chef generate='$error'" ;
  exit $error ;
fi ;



#


#
