package XHTML::Class::Role::Info;
use Moose::Role;
# no warnings "uninitialized";
use namespace::autoclean;
use Carp;

use HTML::Tagset 3.02 ();

my $_known  = { %HTML::Tagset::isKnown }; # Copy; we modify this one.
my $_empty  = \%HTML::Tagset::emptyElement;
my $_body   = \%HTML::Tagset::isBodyElement;
my $_phrase = \%HTML::Tagset::isPhraseMarkup;
my $_form   = \%HTML::Tagset::isFormElement;
my $_block  = { map {; $_ => 1 }
                grep { ! ( $_phrase->{$_} || $_form->{$_} ) }
                keys %{$_body}
               };
# Accommodate HTML::TokeParser's idea of a "tag."
$_known->{"$_/"} = 0 for keys %{$_empty};

sub tags {
    grep { ! /\W/ } sort keys %{$_known};
}

sub known {
    defined $_known->{$_[1]};
}

sub block_level {
    $_block->{$_[1]};
}

sub phrasal {
    $_phrase->{$_[1]};
}


1;

__END__


has "known" =>
    is => "ro",
    isa => "HashRef",
    required => 1,
    default
    ;




__END__
has "tags" => 
    is => "ro",
    isa => "HashRef",
    lazy => 1,
    builder => "_make_tags",
    ;
