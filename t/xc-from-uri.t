use warnings;
use strict;
use Test::More;
use XHTML::Class;
use URI;
use HTTP::Daemon;
use File::Spec;
use FindBin;
use utf8;

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
