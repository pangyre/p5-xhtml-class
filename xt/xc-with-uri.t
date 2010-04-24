use warnings;
use strict;
use Test::More;
use XHTML::Class;
use URI;

# THIS SHOULD START A LOCAL SERVER OR SOMETHING INSTEAD...?
# And use Plack or skip and be in the main kit.
{
    my $likely_to_be_there = URI->new("http://google.com");

    ok( my $xu = XHTML::Class->new($likely_to_be_there),
        "XHTML::Util->new( URI:google.com )" );

    ok( $xu->is_document,
        "Internet document is an Internet document" );

    like( $xu, qr/Google/, "Oh, hai, Google" );

}

done_testing();

__END__
