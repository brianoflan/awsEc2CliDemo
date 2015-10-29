#!/bin/bash

# # # USAGE:
# # #  idemSecGrpRule.sh $secGrpId $secGrpRulePort $secGrpRuleProtocol $secGrpRuleExclusiveIp $secGrpRuleXIpCidrBits
# # #                    $1        $2              $3                  $4                     $5

defaultPort=22 ;
defaultProtocol='tcp' ;
defaultXIp='' ;
defaultXIpCidrLeadingBits=24 ;

if [[ -z $1 ]] ; then
  if [[ -z $secGrpId ]] ; then
    echo "ERROR:  Inadequate args"'!' 1>&2 ;
    echo " Usage:  idemSecGrpRule.sh \$secGrpId" 1>&2 ;
    exit 1 ;
  fi ;
else
  export secGrpId=$1 ;
fi ;

if [[ -z $2 ]] ; then
  if [[ -z $secGrpRulePort ]] ; then
    export secGrpRulePort="$defaultPort"
    echo "WARNING:  No port specified, assuming port 22." 1>&2 ;
  fi ;
else
  export secGrpRulePort=$2 ;
fi ;

if [[ -z $3 ]] ; then
  if [[ -z $secGrpRuleProtocol ]] ; then
    export secGrpRuleProtocol="$defaultProtocol"
  fi ;
else
  export secGrpRuleProtocol=$3 ;
fi ;

if [[ -z $4 ]] ; then
  if [[ -z $secGrpRuleExclusiveIp ]] ; then
    export secGrpRuleExclusiveIp="$defaultXIp"
  fi ;
else
  export secGrpRuleExclusiveIp=$4 ;
fi ;

if [[ -z $5 ]] ; then
  if [[ -z $secGrpRuleXIpCidrBits ]] ; then
    export secGrpRuleXIpCidrBits="$defaultXIpCidrLeadingBits"
  fi ;
else
  export secGrpRuleXIpCidrBits=$5 ;
fi ;

myIpv4Cidr="$secGrpRuleExclusiveIp/$secGrpRuleXIpCidrBits" ;


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

# # From idemSecGrp:
# $vpcId $secGrpName $secGrpDesc
f=$tmp/awsEc2SecGroups.txt ;

if [[ ! -e $f ]] ; then
  echo "ERROR:  Please run idemSecGrp.sh first.  (I can't find $f.)" 1>&2 ;
  exit 1 ;
fi ;

cat $f | perl $thisDir/listRules.pl > $tmp/sgRules.txt 2> $tmp/sgRules.err ;

# alreadyARule=`cat $tmp/sgRules.txt | grep ingress | egrep "ALLOWS[ \t][ \t]*tcp[ \t]22[ \t]" ` ;
alreadyARule=`cat $tmp/sgRules.txt | grep ingress | perl -ne "/ALLOWS\\s+${secGrpRuleProtocol}\\s+${secGrpRuleProtocol}\\s/ && print \$_" ` ;
if [[ $alreadyARule ]] ; then
  # echo "TCP 22 is already a rule."
  # echo "Already a rule (TCP 22)."
  echo "Already a rule (${secGrpRuleProtocol} ${secGrpRulePort})."
else

  # cmdX="ec2-authorize $USE_THIS_SEC_GRP -P tcp -p 22 -s ${myIpv4}/24" ;
  # cmdX="ec2-authorize $secGrpId -P tcp -p 22 -s ${myIpv4}/24" ;
  cmdX="ec2-authorize $secGrpId -P $secGrpRuleProtocol -p $secGrpRulePort" ;
  if [[ -n $secGrpRuleExclusiveIp ]] ; then
    cmdX="$cmdX -s ${myIpv4Cidr}" ;
  fi ;
  echo "  Cmd: $cmdX" ;
  error='' ;
  $cmdX ; error=$? ;
  if [[ $error -gt 0 ]] ; then
    echo "  Error (non-zero exit code, $error) from command." 1>&2 ;
    exit $error ;
  fi ;
fi ;

exit 0 ;

#
