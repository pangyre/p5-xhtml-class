package XHTML::Class::Role::Core;
use Moose::Role;
# no warnings "uninitialized";
use namespace::autoclean;
use Carp;
# requires qw(  );

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

1;

__END__
