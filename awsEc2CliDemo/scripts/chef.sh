#!/bin/bash

export LC_ALL='en_US.UTF-8' ;
export LANGUAGE='en_US.UTF-8' ;
export LANG='en_US.UTF-8' ;

useChefZeroOrChefClient='zero' ; # 'zero' or 'client'
chefDkOmnibusUrl='https://opscode-omnibus-packages.s3.amazonaws.com/el/7/x86_64/chefdk-0.10.0-1.el7.x86_64.rpm' ;
forChefDkUseOmnibusRpm='1' ; # blank '' for false
vagrantUrl='https://releases.hashicorp.com/vagrant/1.7.4/vagrant_1.7.4_x86_64.rpm' ;
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

runSshCmd() {
  if [[ -z $DEBUG ]] ; then
    DEBUG='' ;
  fi ;
  what="$1" ;
  cmd="$2" ;
  user="$3" ;
  if [[ -z $user ]] ; then
    user="$useUser2" ;
  fi ;
  ssh -i $thisDir/$privKey.pem $user@$extIp bash -c "echo ; export PATH=\"/home/$user/bin:\$PATH\" ; $cmd ; echo \$?" \
    > $thisDir/$tmp/$what 2>&1 || error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "error with $what = '$error'" 1>&2 ;
    if [[ $error -eq 128 ]] ; then
      echo "Maybe ignoring exit code 128." 1>&2 ;
      error=`tail -1 $thisDir/$tmp/$what` 1>&2 ;
    fi ;
    if [[ $error -gt 0 ]] ; then
      echo "Actual error='$error'." 1>&2 ;
      cat $thisDir/$tmp/$what ;
      exit $error ;
    fi ;
  fi ;
  if [[ $DEBUG ]] ; then
    echo "Output from $what:" 1>&2 ;
    cat $thisDir/$tmp/$what 1>&2 ;
  fi ;
}


#

#

extIp=`/bin/bash $thisDir/getExtIp.sh '' $workstationInternalIp ` ;
echo -e "extIp $extIp\n" 1>&2 ;

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

x=`ssh -i $thisDir/$privKey.pem $useUser1@$extIp ls -d vagrant.rpm 2>/dev/null ` ;
if [[ -z $x ]] ; then
  # echo "vagrantUrl $vagrantUrl" 1>&2 ;
  cmdX="curl -o vagrant.rpm $vagrantUrl " ;
  echo "cmdX q($cmdX)" 1>&2 ;
  # ssh -i $thisDir/$privKey.pem $useUser1@$extIp /bin/bash -c "curl -o vagrant.rpm $vagrantUrl " 1>&2 || error=$? ;
  ssh -i $thisDir/$privKey.pem $useUser1@$extIp $cmdX 1>&2 || error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "error='$error'" ;
    exit $error ;
  fi ;
fi ;

x=`ssh -i $thisDir/$privKey.pem $useUser1@$extIp yum list installed vagrant 2>/dev/null | egrep -v '^Loaded plugins' ` ;
# # #
if [[ -z $x ]] ; then
  ssh -i $thisDir/$privKey.pem $useUser1@$extIp -t -t sudo rpm -Uvh vagrant.rpm 1>&2 || error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "error with rpm install vagrant.rpm = '$error'" ;
    exit $error ;
  fi ;
else
  echo "yum list installed vagrant = q($x)" 1>&2 ;
fi ;

  
# # # NOW AS USER2

if [[ $forChefDkUseOmnibusRpm ]] ; then
  gitDkUrl='' ;
fi ;

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
  bn=`basename $url | sed -e 's/[.]git$//'` ;
  echo "url bn $bn" 1>&2 ;
  if [[ '' ]] ; then
    ssh -i $thisDir/$privKey.pem $useUser2@$extIp bash -c "echo ; cd $bn && pwd && git fetch origin && git rebase origin/master ; echo \$?" \
      > $thisDir/$tmp/gitFetchRebase 2>&1 || error=$? ;
    if [[ $error -gt 0 ]] ; then
      echo "error with git fetch rebase = '$error'" ;
      if [[ $error -eq 128 ]] ; then
        echo "Maybe ignoring exit code 128." ;
        error=`tail -1 $thisDir/$tmp/gitFetchRebase` ;
        echo "Actual error='$error'." ;
      fi ;
      if [[ $error -gt 0 ]] ; then
        cat $thisDir/$tmp/gitFetchRebase ;
        exit $error ;
      fi ;
    fi ;
    echo "Output from git fetch rebase:" 1>&2 ;
    cat $thisDir/$tmp/gitFetchRebase 1>&2 ;
  else
    runSshCmd "gitFetchRebase_v2" "cd $bn && pwd && git fetch origin && git rebase origin/master" ;
  fi ;
done ;

if [[ $forChefDkUseOmnibusRpm ]] ; then

  x=`ssh -i $thisDir/$privKey.pem $useUser2@$extIp ls -d /var/tmp/chef-dk.rpm 2>/dev/null ` ;
  if [[ -z $x ]] ; then
    cmdX="curl -o /var/tmp/chef-dk.rpm $chefDkOmnibusUrl " ;
    echo "cmdX q($cmdX)" 1>&2 ;
    ssh -i $thisDir/$privKey.pem $useUser2@$extIp $cmdX 1>&2 || error=$? ;
    if [[ $error -gt 0 ]] ; then
      echo "error with curl chefDkOmnibusUrl = '$error'" ;
      exit $error ;
    fi ;
  fi ;

  # User1 for sudo
  x=`ssh -i $thisDir/$privKey.pem $useUser1@$extIp ls -d /opt/chefdk 2>/dev/null ` ;
  # # # Just as good?
  # x=`ssh -i $thisDir/$privKey.pem $useUser1@$extIp yum list installed chefdk 2>/dev/null | egrep -v '^Loaded plugins' ` ;
  # # #
  if [[ -z $x ]] ; then
    ssh -i $thisDir/$privKey.pem $useUser1@$extIp -t -t sudo rpm -Uvh /var/tmp/chef-dk.rpm 1>&2 || error=$? ;
    if [[ $error -gt 0 ]] ; then
      echo "error rpm update chef-dk.rpm = '$error'" ;
      if [[ $error -eq 128 ]] ; then
        echo "Ignoring exit code 128." ;
      else
        exit $error ;      
      fi ;
    fi ;
  fi ;

else

  # x=`ssh -i $thisDir/$privKey.pem $useUser2@$extIp /bin/bash -c "gem query --local | egrep 'chef' " ` ;
  x=`ssh -i $thisDir/$privKey.pem $useUser2@$extIp gem query --local | egrep '^chef.dk' ` ;
  echo "gem query local chef.dk ='$x'" 1>&2 ;
  if [[ -z $x ]] ; then
    ssh -i $thisDir/$privKey.pem $useUser2@$extIp /bin/bash -c "cd chef-dk ; gem install bundler chef-dk" 1>&2 || error=$? ;
    if [[ $error -gt 0 ]] ; then
      echo "error with gem install chef-dk='$error'" ;
      # exit $error ; # Exits 128 even if successful.
      if [[ $error -eq 128 ]] ; then
        echo "Ignoring exit code 128." ;
      else
        exit $error ;      
      fi ;
    fi ;
  fi ;
  
fi ;

error='' ;

x=`ssh -i $thisDir/$privKey.pem $useUser2@$extIp ls -d $tutDemoDir/cookbooks/hello_chef_server 2>/dev/null ` ;
if [[ -z $x ]] ; then
  # ssh -i $thisDir/$privKey.pem $useUser2@$extIp /bin/bash -c "echo ; echo PATH ; echo \$PATH ; echo \"/home/$useUser2/chef-dk/bin:\$PATH\" ; export PATH=\"/home/$useUser2/chef-dk/bin:\$PATH\" ; cd $tutDemoDir ; pwd ; echo PATH ; echo \$PATH ; which chef ; chef generate cookbook cookbooks/hello_chef_server" 1>&2 || error=$? ;
  ssh -i $thisDir/$privKey.pem $useUser2@$extIp /bin/bash -c "echo ; export PATH=\"/home/$useUser2/chef-dk/bin:\$PATH\" ; cd $tutDemoDir ; chef generate cookbook cookbooks/hello_chef_server" 1>&2 || error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "error with chef generate='$error'" ;
    # # exit $error ; # Exits 128 even if successful.
    exit $error ;
  fi ;
fi ;

if [[ "zero" == "$useChefZeroOrChefClient" ]] ; then
  if [[ '1' ]] ; then
    x=`ssh -i $thisDir/$privKey.pem $useUser2@$extIp gem query --local | egrep '^chef.zero' ` ;
    echo "gem query local chef.zero ='$x'" 1>&2 ;
    if [[ -z $x ]] ; then
      runSshCmd "gemInstallChefZero" "gem install chef-zero" ;
    fi ;
  fi ;
  
  if [[ '1' ]] ; then
    x=`ssh -i $thisDir/$privKey.pem $useUser2@$extIp ls -d /var/tmp/chef-zero.pid ` ;
    echo "existing chef-zero.pid file ='$x'" 1>&2 ;
    if [[ $x ]] ; then
      runSshCmd "runChefZero" "bash -c \"kill -15 \$(/var/tmp/chef-zero.pid) ; rm -f /var/tmp/chef-zero.pid\"" ;
    fi ;
    bn=`basename $gitRepo | sed -e 's/[.]git$//'` ;
    runSshCmd "runChefZero" "bash $bn/cookbooks/do_tut2/templates/default/runChefZero.sh.erb" ;
    x=`ssh -i $thisDir/$privKey.pem $useUser2@$extIp ls -ld $bn 2>/dev/null | egrep '^l' ` ;
    if [[ -z $x ]] ; then
      runSshCmd "linkHomeChefRepo" "mv $bn chef-repo ; ln -s chef-repo/ $bn" ;
    fi ;
    runSshCmd "knifeUpload" "cd chef-repo && knife upload cookbooks" ;
    # runSshCmd "chefClientLocal_do_tut2" "chef-client --local-mode --runlist 'recipe[do_tut2]'" ;
    
    runSshCmd "chefClientLocal_do_tut2" "cd $bn/cookbooks/do_tut2 ; berks install ; berks upload ; chef-client -c ~/chef-repo/.chef/knife.rb -o do_tut2" ;
  fi ;
else # chef-client
  true ;
fi ;

#
