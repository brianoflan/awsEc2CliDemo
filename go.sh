#!/bin/bash

cleanIvyCache='1' ; # '' (blank) to leave Ivy cache alone.

if [[ $cleanIvyCache ]] ; then
  maxOld=99 ;
  n=1 ;
  ivyOld=~/.ivy2.old$n ;
  while [[ -e "$ivyOld" && n -lt $maxOld ]] ; do
    n=$((n+1)) ;
    ivyOld=~/.ivy2.old$n ;
  done ;
  if [[ $n -eq $maxOld ]] ; then
    rm -rf ~/.ivy2.bak 2>/dev/null ;
    mv ~/.ivy2.old$(n-1) ~/.ivy2.bak ;
    rm -rf ~/.ivy2.old* ;
    n=1 ;
    ivyOld=~/.ivy2.old$n ;
  fi ;
  mv ~/.ivy2 "$ivyOld" ;
fi ;

rm -rf ../ivy_repo4/org.example ;
./build.sh clean ;

echo -e '\n\n' ;
echo 'Building:' ;

# ( ./build.sh && ./build.sh && ./build.sh promote ) > out.tmp.txt 2>&1 ;
( ./build.sh ) > out.tmp.txt 2>&1 ;

tail out.tmp.txt ;

#
