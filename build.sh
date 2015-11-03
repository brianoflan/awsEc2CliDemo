#!/bin/bash

basedir=`dirname $0` ;
if [[ "$basedir" == "" ]] ; then
  basedir='.' ;
fi ;
cd $basedir ;

moduleList='' ;

thereAreModuleFolders=`ls -d module* 2>/dev/null | tac` ;
if [[ $thereAreModuleFolders ]] ; then
  moduleList=$thereAreModuleFolders ;
else
  moduleList=$(find . -maxdepth 1 -type d | egrep -v '^[.]$' | egrep -v '[.]old$' | tac ) ;
  # echo "moduleList = q(${moduleList})" ;
fi ;

# for d in `ls -d mod* | tac` ; do
for d in $moduleList ; do
  error=0 ;
  cd "$d" && ant "$@" || error="$?" ;
  if [[ $error -gt 0 ]] ; then
    echo "Error with $d: $error." ;
    exit 1 ;
  fi ;
  cd .. ;
done ;

#
