package Data::Domain::Code;

use strict;
use warnings;
use Carp;
our @ISA = 'Data::Domain';

use Exporter 'import';
our @EXPORT_OK = qw(Code); 
sub Code { __PACKAGE__->new(@_) }

sub new {
    my $class   = shift;
    my @options = qw/-coderefs/;
    my $self = Data::Domain::_parse_args(\@_, \@options, -coderefs => 'arrayref');
    bless $self, $class;

    $self->{-coderefs} and ref($self->{-coderefs}) eq 'ARRAY'
        or croak "Code: invalid coderefs";

    return $self;
}

sub _inspect {
    my ( $self, $data, $context ) = @_;

    for my $code ( @{ $self->{-coderefs} } ) {
        my ($msg_id, @args) = $code->( $context, $data );

        if ( $msg_id ) {
            return $self->msg($msg_id => @args);
        }
    }

    return;
}

1;
