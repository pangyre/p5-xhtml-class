package XHTML::Class::Role::Core;
use Moose::Role;
# no warnings "uninitialized";
use namespace::autoclean;
use Carp;
# requires qw(  );

sub title {
    my $self = shift;
    my $new_title = shift;
    my $title = [ $self->findnodes("//head/title") ]->[0]->firstChild;
    if ( defined $new_title )
    {
        $title->setData( $new_title );
    }
    $title->data;
}

sub strip_tags {
    my $self = shift;
    my $xpath = $self->selector_to_xpath(+shift);
    for my $node ( $self->findnodes($xpath) )
    {
        next if $node->isEqual( $self->body )
            or $node->isEqual( $self->root );
        my $fragment = $self->new_fragment;
        for my $n ( $node->childNodes )
        {
            $fragment->appendChild($n);
        }
        $node->replaceNode($fragment);
    }
    $self;
}

sub strip_style {
    my $self = shift;
    # <links /> too?
    my $xpath = $self->selector_to_xpath(+shift);
    $_->removeAttribute("style") for $self->findnodes($xpath);
    $self;
}

sub remove {
    my $self = shift;
    my $xpath = $self->selector_to_xpath(+shift);
    for my $node ( $self->findnodes($xpath) )
    {
        $node->parentNode->removeChild($node);
    }
    $self;
}

sub traverse {
    my $self = shift;

}

sub same_same {
    my $self  = shift;
    my $other = shift;
    my $self2 = blessed($other) eq blessed($self) ?
        $other : $self->new($other);

    my $blanks = $self->libxml->keep_blanks;
    $self->libxml->keep_blanks(0);

    # Does this even make sense...?
    my $one = $self->libxml->parse_string($self->root->serialize(0))->serialize(0);
    my $two = $self->libxml->parse_string($self2->root->serialize(0))->serialize(0);

    $self->libxml->keep_blanks($blanks); # Restore.

    $one eq $two;#  or die "$one\n\n$two"
}


1;

__END__
