use warnings;
use strict;
use Test::More;
use XHTML::Class;
use URI;
use HTTP::Daemon;
use HTTP::Status;
use File::Spec;
use FindBin;
use utf8;

# <title>The Fox and the Stork » The Æsop for Children  with pictures by Milo Winter</title>

my $server = HTTP::Daemon->new || BAIL_OUT("Can't make an HTTP::Daemon");

my $uri = URI->new( $server->url );

my $kid = fork();
die "Can't fork()" unless defined $kid;

if ( $kid == 0 )
{
    my $server_file = File::Spec
        ->catfile( $FindBin::Bin, qw( files basic.html ) );
    $server->accept->send_file_response($server_file);
}
else
{
    ok( my $xc = xc($uri), "New from URI" );

    is( $xc->type, "document", "Got a document" );

    like( $xc->title,
          qr/The Fox and the Stork » The Æsop for Children/,
          "Title in utf8 is good" );

    waitpid($kid, 0);
    done_testing();
}

__END__


{
    my $likely_to_be_there = URI->new("http://google.com");

    ok( my $xu = XHTML::Class->new($likely_to_be_there),
ÃÂ The         "XHTML::Util->new( URI:google.com )" );

    ok( $xu->is_document,
        "Internet document is an Internet document" );

    like( $xu, qr/Google/, "Oh, hai, Google" );

}

done_testing();

__END__



use warnings;
use strict;
use Test::More;
# use Test::Exception;
use XHTML::Class;

{
    package whatwhat;
    use Test::More;
    use URI;

    ok(1);
}

ok(0);

done_testing();

__END__

dies_ok( sub { my $xc = XHTML::Class->new },
         "XHTML::Class->new dies without content" );

{
    ok( my $xc = XHTML::Class->new("30"),
ÃÂsop for Children/        'XHTML::Class->new("30")' );
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
