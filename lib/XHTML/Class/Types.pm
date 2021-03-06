use Moose;
use Moose::Util::TypeConstraints;
use namespace::clean;
use Carp qw( croak );

enum "DWIMtype" => qw( document fragment );

subtype "XC::URI" => as class_type("URI");
subtype "XC::Source" => as "Str";
coerce  "XC::Source"
    => from "XC::URI" # What about file URIs?
        => via {
            #my $type ::file, ::https?
            require LWP::UserAgent;
            LWP::UserAgent->new->get($_)->decoded_content;
        }
    => from "Object"
        => via {
            $_->can("serialize") ?
                $_->serialize : $_->can("slurp") ?
                scalar($_->slurp) : $_->can("as_string") ?
                $_->as_string : $_->can("as_HTML") ?
                $_->as_HTML : $_->can("as_text") ?
                $_->as_text : $_->can("as_string") ?
                $_->as_string : $_->can("getlines") ?
                scalar($_->getlines) : confess("Couldn't figure out what to do with $_");
        }
    ;

sub _slurp {
    my $name = shift;
    open my $f, "<", $name or croak "Couldn't open $name for reading: $!";
    local $/;
    do { <$f> };
}

1;

__END__

    => from "Str"
    => via {
        confess "OH NOES";
        -e $_ ? _slurp($_) : $_;
    }


#subtype "XC::LibXML::Element" => as class_type("XML::LibXML::Element");
#subtype "XC::LibXML::Doc" => as class_type("XML::LibXML::Document");
#subtype "XC::Path::Class" => as class_type("Path::Class::File");


    => from "XC::LibXML::Element"
        => via { $_->serialize }
    => from "XC::LibXML::Doc"
        => via { $_->serialize }


sub _from_string {
    my $str = shift;
    XML::LibXML->new->parse_html_string($str);
}


Object
  can getline?

    => from "XML::LibXML::Document"
    => via { $_ }
    => from "XML::LibXML::Element"
    => via { $_ }
    => from "URI"
    => via { $_ }
    => from "Path::Class"
    => via { $_ }

  use HTTP::Headers  ();
  use Params::Coerce ();
  use URI            ();

  subtype 'My::Types::HTTP::Headers' => as class_type('HTTP::Headers');




subtype 'My::Types::HTTP::Headers' => as class_type('HTTP::Headers');
    required => 1,
  coerce 'My::Types::URI'
      => from 'Object'
    => via { $_->isa('URI')
                   ? $_
                   : Params::Coerce::coerce( 'URI', $_ ); }
      => from 'Str'
    => via { URI->new( $_, 'http' ) };
