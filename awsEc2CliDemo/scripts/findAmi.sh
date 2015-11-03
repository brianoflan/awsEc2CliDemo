#!/bin/bash

defaultOwner='amazon' ; # '' (blank) to look for any owner
defaultRootDev='ebs' ;
grepOut="(BLOCKDEVICEMAPPING|elasticbeanstalk|minimal|suse|windows)" ;
grepFor=`date -u +'%Y-%m'` ;

if [[ -z $findAmi_owner ]] ; then
  findAmi_owner=$defaultOwner ;
fi ;
if [[ -z $findAmi_rootDev ]] ; then
  findAmi_rootDev=$defaultRootDev ;
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


# # # MAIN

  # cmdX="ec2-describe-images -a -o amazon --filter \"is-public=true\" -F \"architecture=x86_64\" --filter \"platform=linux\" " ;
  # cmdX="ec2-describe-images -o amazon --filter \"is-public=true\" -F \"architecture=x86_64\" --filter \"platform=linux\" " ;
  #   -F \"root-device-type=instance-store\" \
  #   -F \"virtualization-type=paravirtual\" \
  cmdX="ec2-describe-images" ;
  if [[ -n $findAmi_owner ]] ; then
    cmdX="$cmdX -o ${findAmi_owner}" ;
  fi ;
  cmdX="$cmdX -F \"is-public=true\" -F \"image-type=machine\" \
    -F \"architecture=x86_64\" \
    -F \"virtualization-type=hvm\" \
    -F \"root-device-type=${findAmi_rootDev}\" \
    " ;
  true ;
  echo "Cmd: $cmdX" ;
  error='' ;
  # $cmdX | egrep -vi '(BLOCKDEVICEMAPPING|elasticbeanstalk|minimal|suse|windows)' | egrep '2015[\-]09' > $tmp/images.txt ; error=$? ;
  $cmdX | egrep -vi "$grepOut" | perl -ne "/\\Q${grepFor}\\E/ && print \$_" > $tmp/images.txt ; error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "Error (non-zero exit code) from command." ;
  fi ;
  cat $tmp/images.txt | sort | tail ;
  cat $tmp/images.txt | wc -l ;
  #
#

#
