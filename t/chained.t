use warnings;
use strict;
use Test::More;
use FindBin;
use Path::Class;
use XHTML::Class;
use Algorithm::Diff;
use Encode;

{
    my $basic = Path::Class::File->new("$FindBin::Bin/files/basic.html");
    ok( my $xc = XHTML::Class->new($basic),
        "XHTML::Class->new files/basic.html->slurp" );

    #    $xc->debug(3);

    my @tags = grep { ! /\A(p|a|script|head)\z/ } $xc->tags;

    ok( $xc
        ->fix
        ->traverse("//*/text()", sub {
                       my $node = shift;
                       my $text = $node->data;
                       $text =~ s/([^\S\n]*\n[^\S\n]*)+/\n/g;
                       $node->setData( $text );
                   })
        ->remove("script, head")
        ->strip_tags(join(",", @tags))
        ->enpara(),
        "Bunch o'stuff chained together..." );

    ok( $xc->strip_tags(join(",", @tags)) );
    # diag($xc) if $ENV{TEST_VERBOSE};
}

done_testing();

__END__
