use warnings;
use strict;
use Test::More;
use XHTML::Class;

{
    ok( my @tags = XHTML::Class->tags,
        "List of tags" );

    cmp_ok( @tags, ">=", 100,
            "100 or better tags" );
}

done_testing();

__END__
