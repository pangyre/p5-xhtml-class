use warnings;
use strict;
use Test::More;
use Test::Exception;
use FindBin qw( $Bin );
use File::Spec;
use Path::Class;
use lib File::Spec->catfile($Bin, '../lib');
use XHTML::Class;

dies_ok( sub { my $xc = XHTML::Class->new },
         "XHTML::Class->new dies without content" );

{
    ok( my $xc = XHTML::Class->new("30"),
        'XHTML::Class->new("30")' );
    isa_ok( $xc, "XHTML::Class" );
    ok( $xc->is_valid, "Basic document is valid");
}

{
    my $before = Path::Class::File->new("$FindBin::Bin/files/basics-before.txt")->slurp;
    my $after = Path::Class::File->new("$FindBin::Bin/files/basics-after.txt")->slurp;
    cmp_ok( $before, "ne", $after,
            "Sanity check: before and after differ");

    ok( my $xc = XHTML::Class->new($before),
        "XHTML::Class->new(\$before)" );

    ok( $xc->is_fragment, "Type is fragment" );

#    $xc->debug(3);

    is(XHTML::Class::_trim($xc->as_string), XHTML::Class::_trim($before),
       "Original content matches stringified object");

    ok( $xc->enpara(),
        "Enpara'ing the content" );

#    is(XHTML::Class::_trim($xc->as_string),
#       XHTML::Class::_trim($before) 

    is( XHTML::Class::_trim($xc),
        XHTML::Class::_trim($after),
        "Enpara'ed content of 'before' matches raw 'after'" );
}

{
    ok( my $xc = XHTML::Class->new("$FindBin::Bin/files/basic.html"),
        "XHTML::Class->new(basic.html)" );
#    diag("OUT: " . $xc->as_string());
}

{
    my $xc = XHTML::Class->new('<script type="text/javascript">alert("OH HAI")</script>');
    ok( $xc->strip_tags('script'),
        "Stripping script tags" );
    is( $xc->as_string, '<![CDATA[alert("OH HAI")]]>',
        "Smooth as mother's butter" );
}

done_testing();

__END__
