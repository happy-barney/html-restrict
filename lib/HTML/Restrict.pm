package HTML::Restrict;

use Moose;

use Data::Dump qw( dump );
use HTML::Parser;
use MooseX::Params::Validate;
use Perl6::Junction qw( any );

has 'debug' => (
    is          => 'rw',
    isa         => 'Bool',
    default     => 0,
);

has 'rules' => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 0,
    default     => sub { {} },
    trigger     => \&_build_parser,
    reader      => 'get_rules',
    writer      => 'set_rules',
);

has 'parser' => (
    is          => 'ro',
    lazy        => 1,
    builder     => '_build_parser',
);

has '_processed' => (
    is          => 'rw',
    isa         => 'Str',
    clearer     => '_clear_processed',
);

=head1 NAME

HTML::Restrict - Strip away unwanted HTML tags

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module uses HTML::Parser to strip HTML from text in a restrictive manner.
By default all HTML is restricted.  You may alter the default behaviour by
supplying your own tag rules.

For example.

    use HTML::Restrict;

    my $hr = HTML::Restrict->new();

    # use default rules to start with (strip away all HTML)
    my $processed = $hr->process('<b>i am bold</b>');

    # $processed now equals: i am bold

Now, a less restrictive example:

    use HTML::Restrict;

    my $hr = HTML::Restrict->new();
    $hr->set_rules({
        b   => [],
        img => [qw( src alt / )]
    });

    my $html = q[<body><b>hello</b> <img src="pic.jpg" alt="me" id="test" /></body>];
    my $processed = $hr->process( $html );

    # $processed now equals: <b>hello</b> <img src="pic.jpg" alt="me" />

=head1 SUBROUTINES/METHODS

=head2 process( "<html>...</html>" )

This is the method which does the real work.  It parses your data, removes any
tags and attributes which are not specifically allowed and returns the
resulting text.  Requires and returns a SCALAR.

=head2 get_rules

An accessor method, which returns a HASHREF of allowed tags and their
allowed attributes.  Returns an empty HASHREF by default.

=head2 set_rules( { a => [], img => [qw( src alt ), ...] })

Sets the rules which will be used to process your data.  By default all HTML
tags are off limits.  Use this method to define the HTML elements and
corresponding attributes you'd like to use.

Please note that set_rules is a mutator method, so your changes are not
cumulative.  The last rules passed to the set_rules method are the rules which
will be applied to your data when it is processed.

For example:

    # allow only b (bold) tags
    $hr->set_rules({ b => [] })

    # return to defaults (no HTML allowed)
    $hr->set_rules({});

    # all b tags plus images
    # allow some image attributes as well
    $hr->set_rules({ b => [], img => [qw( src alt width height border / )]});

Since HTML::Parser treats a closing slash as an attribute, you'll need to add
"/" to your list of allowed attributes if you'd like your tags to retain
closing slashes.  For example:

    $hr->set_rules({ hr => [] });
    $hr->process( "<hr />"); # returns: <hr>

    $hr->set_rules({ hr => [qw( / )] });
    $hr->process( "<hr />"); # returns: <hr />

HTML::Restrict strips away any tags and attributes which are not explicitly
allowed. It also rebuilds your explicitly allowed tags and places their
attributes in the order in which they appear in your rules.

So, if you define the following rules:

    $hr->set_rules({
        ...
        img => [qw( src alt title width height id / )]
        ...
    })

then your image tags will all be built like this:

    <img src=".." alt="..." title="..." width="..." height="..." id=".." />

This gives you greater consistency in your tag layout.  If you don't care
about element order you don't need to pay any attention to this, but you
should be aware that your elements are being reconstructed rather than just
stripped down.

=cut

sub _build_parser {

    my $self    = shift;
    print "*************** building parser\n" if $self->debug;
    return HTML::Parser->new(

        start_h => [
            sub {
                my ( $p, $tagname, $attr, $text ) = @_;
                print "name:  $tagname", "\n" if $self->debug;

                my $more = q{};
                if ( any( keys %{ $self->get_rules } ) eq $tagname  ) {
                    print dump $attr if $self->debug;
                    foreach my $attribute ( @{ $self->get_rules->{$tagname} } ) {
                        if ( $attr->{$attribute} && $attribute ne q{/} ) {
                            $more .= qq[ $attribute="$attr->{$attribute}" ];
                        }
                    }

                    # closing slash should (naturally) closing the tag
                    if ( exists $attr->{q{/}} && $attr->{q{/}} eq q{/} ) {
                        $more .= ' /';
                    }

                    my $elem = "<$tagname $more>";
                    $elem =~ s{\s*>}{>}gxms;
                    $elem =~ s{\s+}{ }gxms;

                    $self->_processed( ( $self->_processed || q{} ) . $elem );
                }
            },
            "self,tagname,attr,text"
        ],

        end_h => [
            sub {
                my ( $p, $tagname, $attr, $text ) = @_;
                if ( any( keys %{ $self->get_rules } ) eq $tagname  ) {
                    print "text: $text" if $self->debug;
                    $self->_processed( ( $self->_processed || q{} ) . $text );
                }
            },
            "self,tagname,attr,text"
        ],

        text_h =>  [
            sub {
                my ( $p, $text ) = @_;
                print "$text\n" if $self->debug;
                $self->_processed( ( $self->_processed || q{} ) . $text );
            },
            "self,text"
        ],
    );

}

sub process {

    my $self = shift;
    my ( $content ) = pos_validated_list( \@_, { type => 'Str' }, );
    $self->_clear_processed;

    my $parser = $self->parser;
    $parser->parse( $content );
    $parser->eof;

    return $self->_processed;

}

=head1 AUTHOR

Olaf Alders, C<< <olaf at wundercounter.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-html-restrict at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Restrict>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::Restrict


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Restrict>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-Restrict>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-Restrict>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-Restrict/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2009 Olaf Alders.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of HTML::Restrict