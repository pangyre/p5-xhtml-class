use strict;
use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, 'lib');

use Test::More tests => 2;

open my $fh, '<', "$FindBin::Bin/../lib/XHTML/Class.pm"
    or die "Couldn't open self module to read! $!";

my $synopsis = '';
while ( <$fh> ) {
    if ( /=head1 SYNOPSIS/i .. /=head\d (?!S)/
                   and not /^=/ )
    {
        $synopsis .= $_;
    }
}
close $fh;

ok( $synopsis,
    "Got code out of the SYNOPSIS space to evaluate" );

note( $synopsis );

my $ok = eval "$synopsis; print qq{\n}; 1;";

ok( $ok, "Synopsis eval'd" );

note( $@ . "\n" . $synopsis ) if $@;
