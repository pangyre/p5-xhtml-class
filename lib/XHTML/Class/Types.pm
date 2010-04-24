use Moose;
use Moose::Util::TypeConstraints;

# use Params::Coerce ();
use URI ();
use XML::LibXML;

subtype "XHTML::Class::Document" => as class_type("XML::LibXML::Document");
coerce "XHTML::Class::Document"
    => from "Str"
        => via { XML::LibXML->new->parse_html_string($_) }
    ;

1;

__END__

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
