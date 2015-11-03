#!/bin/bash

# # # USAGE:
# # #  idemSecGrp.sh $vpcId $secGrpName $secGrpDesc

if [[ -z $3 ]] ; then
  if [[ -z $secGrpDesc ]] ; then
    export secGrpDesc="Basic Security Group for Amazon EC2 demo 1." ;
  fi ;
else
  export secGrpDesc=$3 ;
fi ;
if [[ -z $2 ]] ; then
  if [[ -z $secGrpName ]] ; then
    export secGrpName="cliDemoSG1" ;
  fi ;
else
  export secGrpName=$2 ;
fi ;
if [[ -z $1 ]] ; then
  if [[ -z $vpcId ]] ; then
    echo "ERROR:  Inadequate args"'!' 1>&2 ;
    echo " Usage:  idemSecGrp.sh \$vpcId \$secGrpName \$secGrpDesc" 1>&2 ;
    exit 1 ;
  fi ;
fi ;

if [[ -z $DO_CLEAN ]] ; then
  export DO_CLEAN="false" ;
fi ;

# tmp=$BUILD_DIR/tmp ;
tmp=$BUILD_DIR/tmpSecGrp ;
if [[ "$DO_CLEAN" == "true" ]] ; then
  if [[ -d $tmp ]] ; then
    rm -rf $tmp ;
  fi ;
fi ;
if [[ ! -d $tmp ]] ; then
  mkdir $tmp ;
fi ;

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

# # http://docs.aws.amazon.com/cli/latest/userguide/cli-ec2-sg.html
# aws ec2 describe-security-groups --group-names $USE_THIS_SEC_GRP
# http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-DescribeSecurityGroups.html
ec2-describe-group -F "vpc-id=$vpcId" > $f ;
echo "  Debug the list of groups:" 1>&2 ;
# egrep '^GROUP' $f | awk '{print $2 "" $3}' ;
echo "    grep GROUP:" 1>&2 ;
egrep '^GROUP' $f | perl -ne 'print "      $_" ' 1>&2 ;
echo "    grep GROUP | awk -F \\t '{print \$2 \" \" \$4}' :" 1>&2 ;
egrep '^GROUP' $f | awk -F $'\t' '{print $2 " " $4}' | perl -ne 'print "      $_" ' 1>&2 ;
echo 1>&2 ;
alreadyExists=$(egrep '^GROUP' $f | awk '{print $2 " " $4}' | perl -ne "/\\Q$secGrpName\\E/ && print $_" ) ;
echo "  alreadyExists: q{$alreadyExists}" 1>&2 ;

if [[ -z $alreadyExists ]] ; then
  echo "  Creating group $secGrpName" 1>&2 ;
  tmp0=`ec2-create-group $secGrpName -d "$secGrpDesc" -c $vpcId && echo $? ` ;
  echo "  tmp0: q{$tmp0}" 1>&2 ;
  # alreadyExists=$(echo "$tmp0" | awk '{print $2 "" $3}' | perl -ne "/\\Q$secGrpName\\E/ && print $_" ) ;
  alreadyExists="$tmp0" ;
else
  echo "Already a security group ($secGrpName)." 1>&2 ;
fi ;

# export secgrpid=`echo "$alreadyExists" | awk '{print $1}'` ;
export secgrpid=`echo "$alreadyExists" | perl -ne '/(^|\s)(sg[\-]\S+)(\s|$)/ && print $2' ` ;
echo "secgrpid = '$secgrpid'" 1>&2 ;
if [[ -z $secgrpid ]] ; then
  echo "ERROR: Failed to determine security group id (from '${alreadyExists}')." 1>&2 ;
  exit 1 ;
fi ;

echo "$secgrpid" ;


#
