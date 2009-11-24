package Data::Domain::Code;

use strict;
use warnings;
use Carp;
use Exporter 'import';

our @EXPORT = qw(Code); 
our @ISA = 'Data::Domain';

sub Code { __PACKAGE__->new(@_) }

sub new {
    my $class   = shift;
    my @options = ();
    my $self    = Data::Domain::_parse_args([], \@options);
    bless $self, $class;

    $self->{codes} = [@_];

    return $self;
}

sub _inspect {
    my ( $self, $data, $context ) = @_;

    for my $code ( @{ $self->{codes} } ) {

        my @ret     = $code->( $context, $data );

        my @scalars = grep { !ref } @ret;
        my @arrays  = grep { ref and ref eq "ARRAY" } @ret;

        my $msg_id  = $scalars[0];
        my $name    = $scalars[1];
        my $args    = $arrays[0] || [];

        if ( $msg_id ) {
            local $self->{-name} = $name if $name;
            return $self->msg($msg_id => @$args);
        }

    }

    return;
}

1;
