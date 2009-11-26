package Data::Domain::All;

use strict;
use warnings;
use Carp;
our @ISA = 'Data::Domain';

use Exporter 'import';
our @EXPORT_OK = qw(All); 
sub All { __PACKAGE__->new(@_) }

sub new {
    my $class = shift;
    my @options = qw/-domains/;
    my $self = Data::Domain::_parse_args(\@_, \@options, -domains => 'arrayref');
    bless $self, $class;

    $self->{-domains} and ref($self->{-domains}) eq 'ARRAY'
        or croak "One_of: invalid domains";

    return $self;
}

sub _inspect {
    my ($self, $data, $context) = @_;

    for my $subdomain (@{$self->{-domains}}) {
        if ( my $msg = $subdomain->inspect($data, $context) ) {
            $self->{error_domain} = $subdomain;
            return $msg;
        }
    }

    return;
}

1;
