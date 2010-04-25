use warnings;
use strict;
use Test::More;
use FindBin;
use File::Spec;
use Path::Class;
use lib File::Spec->catfile($FindBin::Bin, '../lib');
use XHTML::Class;

{
    my $before = Path::Class::File->new("$FindBin::Bin/files/enpara-complex-before.txt")->slurp;
    my $after = Path::Class::File->new("$FindBin::Bin/files/enpara-complex-after.txt")->slurp;

    cmp_ok( XHTML::Class::_trim($before), "ne", XHTML::Class::_trim($after),
            "Before and after differ");

    ok( my $xc = XHTML::Class->new($before),
        "XHTML::Class->new files/enpara-complex-before.txt->slurp" );

    ok( my $enparaed = $xc->enpara,
        "Enpara'ing the content" );

    is( XHTML::Class::_trim($enparaed),
        XHTML::Class::_trim($after),
        "Enpara'ed content of 'before' matches 'after'" );
}

done_testing();

__END__
