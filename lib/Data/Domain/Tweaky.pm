package Data::Domain::Tweaky;

use mro 'c3';
use strict;
use warnings;
use base 'Data::Domain';
use Data::Domain;
use Data::Domain::Code;
use PadWalker qw(peek_my peek_sub);

=head1 SYNOPSIS

* use Data::Domain ':all'の替りに仕様できる。
* messages()がインスタンスに保存される。

=cut

exporting: {
    no strict 'refs';

    my @packages =
        grep { $_ ne __PACKAGE__ }
        grep { $_->isa("Data::Domain") }
        map  { defined *{"${_}ISA"} ? m/^\*(.*)::/ : () } %Data::Domain::;
    my @subclasses;

    for my $orig (@packages) {
        my ($subclass) = $orig =~ m/::([^:]+)$/;
        #(my $subclass = $orig) =~ s/^.*:://;

        my $class = __PACKAGE__."::$subclass";
        @{"${class}::ISA"} = ($orig, __PACKAGE__);
        mro::set_mro($class, 'c3');
        
        *{$subclass} = sub { $class->new(@_) };

        push @subclasses, $subclass;
    }

    our %EXPORT_TAGS = (all => [@subclasses, 'node_from_path']);
    Exporter::export_ok_tags('all');
}

sub inspect {
    my $self = shift;

    if ( $self->messages ) {
        my $orig = ${ peek_sub(\&Data::Domain::msg)->{'$global_msgs'} };
        ${ peek_sub(\&Data::Domain::msg)->{'$global_msgs'} } = $self->messages;
        my $ret  = $self->next::method(@_);
        ${ peek_sub(\&Data::Domain::msg)->{'$global_msgs'} } = $orig;
        return $ret;
    }

    $self->next::method(@_);
}

sub subclass {
    my $self = shift;

    my $class = ref($self) || $self;
    my ($subclass) = $class =~ m/::([^:]+)$/;

    return $subclass;
}

1;
