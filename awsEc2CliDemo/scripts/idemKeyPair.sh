#!/bin/bash

# # # USAGE:
# # #  idemKeyPair.sh $keyPairName
# # #                 $1

defaultKeyPairName='cliDemo1_keyPair1' ;

if [[ -z $1 ]] ; then
  if [[ -z $keyPairName ]] ; then
    keyPairName=$defaultKeyPairName ;
  fi ;
else
  keyPairName=$1 ;
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


# Should resolve to the module's base folder, not the 'build' or 'build/tmp' folder.
keyPairDir=$tmp/../../AwsEc2KeyPairs.d ;
if [[ ! -d $keyPairDir ]] ; then
  execute mkdir -p $keyPairDir ;
fi ;

keyPairFile=$keyPairDir/$keyPairName.keyPairPrivate.pem ;

# $keyPairName

# # http://docs.aws.amazon.com/cli/latest/userguide/cli-ec2-keypairs.html
alreadyAKeypair=`ls -d $keyPairFile 2>/dev/null` ;
if [[ $alreadyAKeypair ]] ; then
  echo "Already have a key pair for keyPairName $keyPairName." 1>&2 ;
else
  cmdX="ec2-create-keypair $keyPairName" ;
  echo "Cmd: $cmdX" 1>&2 ;
  error='' ;
  $cmdX > $tmp/keyPairOutput.txt ; error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "Error (non-zero exit code) from command." 1>&2 ;
    exit $error ;
  fi ;
  sed '1d' $tmp/keyPairOutput.txt > $keyPairFile ;
  chmod 400 $keyPairFile ;
fi ;
alreadyAKeypair=`ls -d $keyPairFile` ;
echo "alreadyAKeypair = '$alreadyAKeypair'" 1>&2 ;
echo "$alreadyAKeypair" ;

exit 0 ;

#
