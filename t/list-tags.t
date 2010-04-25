use strict;
use warnings;
use Test::More "no_plan";
use FindBin;
use File::Spec;
use Path::Class;
use lib File::Spec->catfile($FindBin::Bin, '../lib');
use XHTML::Class;

{
    ok( my $xc = XHTML::Class->new(\"."),
        "Empty object" );

    diag( join(" ", $xc->tags )) if $ENV{TEST_VERBOSE};

    ok( my @tags = $xc->tags,
        "List of tags" );

    cmp_ok( @tags, ">=", 100,
            "100 or better tags" );
}

__END__
