use warnings;
use strict;
use Test::More;
use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, '../lib');
use XHTML::Class;

{
    my $before = <<"BEFORE";
<p><a href="/some/uri">Paragraph one</a>.</p>

<blockquote><p>Paragraph <i><b>two</b>...</i></p></blockquote>
BEFORE

    ok( my $xc = XHTML::Class->new($before),
        "XHTML::Class->new(...)" );

    like( $xc->as_string, qr/<a[^.]+Paragraph one<\/a>./,
          '<a/> is in object');

    ok( $xc->remove("p a"), "Remove <a/>s inside <p/>s" );

    unlike( $xc->as_string, qr/<a[^.]+Paragraph one<\/a>/,
          '<a/> and its content are gone');

    like( $xc->as_string, qr/<p>\.<\/p>/,
          '"Empty" <p/> remains');

    ok( $xc->remove("b"), "Remove <b/>s" );
    like( $xc->as_string, qr/<i>\.\.\.<\/i>/,
          '<b/> and its content are gone');

    ok( $xc->remove("i"), "Remove <i/>s" );
    like( $xc->as_string, qr/<p>Paragraph <\/p>/,
          '<i/> and its content are gone');

    ok( $xc->remove("p"), "Remove <p/>s" );

    is( $xc->as_string, '<blockquote></blockquote>',
        'Just the empty <blockquote/> left');
}

done_testing();

__END__
