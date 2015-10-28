use strict ; 
use warnings ;
my $secgrpid = $ENV{'secgrpid'} ;
print STDERR "secgrpid='${secgrpid}'.\n" ;
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
    if ( /^\s*GROUP\s+\Q$secgrpid\E/ ) {
      $rightGroup = 1;
      $never = '' ;
    } 
  } 
}
if ( $never ) {
  print STDERR "ERROR: Never found secgrpid '$secgrpid'.\n" ;
}
