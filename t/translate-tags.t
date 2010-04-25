use warnings;
use strict;
use Test::More;
use Test::Exception;
use File::Spec;
use FindBin;
use lib File::Spec->catfile($FindBin::Bin, 'lib');
use XHTML::Class;

ok( my $xc = XHTML::Class->new("something"),
    "XHTML::Class->new " );

dies_ok( sub { $xc->translate_tags('whatever') },
         "Not implemented" );

done_testing();
