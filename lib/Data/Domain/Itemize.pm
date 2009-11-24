package Data::Domain::Itemize;

use utf8;
use Moose;
use namespace::autoclean;

use Data::Domain;
use PadWalker qw(peek_my peek_sub);
use Params::Util ':ALL';
use Try::Tiny;
#use YAML::Syck;

has data => (
    is      => "rw",
    default => sub { {} },
);

has domain => (
    is      => "rw",
    isa     => "Data::Domain",
    default => sub { my $domain = Struct() },
);

has error2text => (
    is      => "rw",
    isa     => "HashRef",
    default => sub {
        ${ peek_sub(\&Data::Domain::messages)->{'$builtin_msgs'} }->{"english"};
    },
);

has field2text => (
    is      => "rw",
    default => sub { {} },
);

has _results => (
    is      => "rw",
    isa     => "HashRef",
    default => sub { {} },
);

__PACKAGE__->meta->make_immutable;
no Moose;

sub itemize {
    my $self = shift;

    my $domain = $self->domain;
    my $data   = $self->data;

    my $orig;

    Data::Domain->messages(sub {
        my ($msg_id, @args) = @_;

        $orig = ${peek_my(1)->{'$global_msgs'}};

        my $name = ${peek_my(1)->{'$name'}};
        return "$name: $msg_id";
    });

    $self->_results( $domain->inspect($data) );
    #warn Dump($domain);
    #warn Dump($results);

    my $keys = [];
    my $msgs = [];
    $self->_walk($domain, $keys, $msgs);

    #Data::Domain->messages($orig);

    @$msgs;
}

sub _field2text {
    my ( $self, @keys ) = @_;

    my @indexes = grep { m/^\d+$/ } @keys;
    my @digit   = map { $_+1 } @indexes;
    my $path    = join(".", map { m/^\d+$/ ? '*' : $_ } @keys);

    sprintf($self->field2text->{$path} || $path, @digit);
}

sub _error2text {
    my ( $self, $error, @keys ) = @_;

    my $field_text = $self->_field2text(@keys);

    # Num: 半角数字で入力してください。
    # String: UNDEFINED

    my ($subclass, $error_id) = split(/\s*:\s*/, $error);
    my $map = $self->error2text;
    my $def = try { $map->{$subclass}{$error_id} || $map->{Generic}{$error_id} };

    if ( _CODE($def) ) {
        $def->( $field_text );
    }
    elsif ( _STRING($def) ) {
        "« ${field_text} » $def";
    }
    else {
        $error =~ m/^\w+:\s(.*)/;
        "« ${field_text} » $1";
    }
}

sub _walk {
    my ( $self, $cur, $paths, $msgs ) = @_;

    if ( _INSTANCE($cur, "Data::Domain::Struct") ) {
        for my $f ( @{$cur->{-fields_list}} ) {
            push @$paths, $f;
            $self->_walk($cur->{-fields}{$f}, $paths, $msgs);
            pop @$paths;
        }
    }
    elsif ( _INSTANCE($cur, "Data::Domain::List") ) {
        my $error_id = do {
            my $pos = $self->_results;
            for (@$paths) {
                if (_HASH($pos)) {
                    $pos = $pos->{$_};
                }
                else {
                    last;
                }
            }
            $pos;
        };

        if ( _STRING($error_id) ) {
            for my $f ( @{$cur->{-all}{-fields_list}} ) {
                push @$paths, $f;
                $self->_walk($cur->{-all}{-fields}{$f}, $paths, $msgs);
                pop @$paths;
            }
        }
        elsif ( _ARRAY($error_id) ) {
            my $i = 0;
            for (@$error_id) {
                for my $f ( @{$cur->{-all}{-fields_list}} ) {
                    push @$paths, $i, $f;
                    $self->_walk($cur->{-all}{-fields}{$f}, $paths, $msgs);
                    pop @$paths;
                    pop @$paths;
                }
                $i++;
            }
        }
    }
    else {
        my @arrived;

        my $pos = $self->_results;
        for (@$paths) {
            if (_HASH($pos)) {
                push @arrived, $_;
                $pos = $pos->{$_};
            }
            elsif (_ARRAY($pos)) {
                push @arrived, $_;
                $pos = $pos->[$_];
            }
            else {
                last;
            }
        }

        if (my $error_id = $pos) {
            my $msg = $self->_error2text($error_id, @arrived);
            push @$msgs, $msg;
        }
    }
}

1;

__END__
--- !!perl/hash:Data::Domain::Struct
-fields:
  images: !!perl/hash:Data::Domain::List
    -all: !!perl/hash:Data::Domain::Struct
      -fields:
        pathname: !!perl/hash:Data::Domain::String {}

      -fields_list:
        - pathname
    -max_size: 10
    -min_size: 1
  land: !!perl/hash:Data::Domain::Struct
    -fields:
      kakaku: !!perl/hash:Data::Domain::Int {}

      latitude: !!perl/hash:Data::Domain::Num
        -messages: 半角数字で入力してください。
      name: !!perl/hash:Data::Domain::String {}

    -fields_list: 
      - name
      - kakaku
      - latitude
  user: !!perl/hash:Data::Domain::Struct
    -fields:
      password: !!perl/hash:Data::Domain::String {}

      retype: !!perl/code: '{ "DUMMY" }'
      username: !!perl/hash:Data::Domain::String {}

    -fields_list:
      - username
      - password
      - retype
-fields_list:
  - user
  - land
  - images
---
images:
  - ~
  - 
    pathname: String, UNDEFINED
  - ~
land:
  kakaku: Int, INVALID
  latitude: "Num: 半角数字で入力してください。"
  name: String, UNDEFINED
user:
  password: String, UNDEFINED
  username: String, UNDEFINED
