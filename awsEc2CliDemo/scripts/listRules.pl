use strict ; 
use warnings ;
my $secGrpId = $ENV{'secGrpId'} ;
print STDERR "secGrpId='${secGrpId}'.\n" ;
my $never = 1 ;
my $rightGroup = '' ;
while (<>) {
  if ( $rightGroup ) {
      if ( /^\s*GROUP/ ) {
        $rightGroup = '';
      } else {
        print $_ ;
      }
  } else { 
    if ( /^\s*GROUP\s+\Q$secGrpId\E/ ) {
      $rightGroup = 1;
      $never = '' ;
    } 
  } 
}
if ( $never ) {
  print STDERR "ERROR: Never found secGrpId '$secGrpId'.\n" ;
}
