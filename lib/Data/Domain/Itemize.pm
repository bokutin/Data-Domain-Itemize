package Data::Domain::Itemize;

use utf8;

use namespace::autoclean;
use Any::Moose;
use Data::Domain;
use Params::Util ':ALL';
use Try::Tiny;
#use YAML::Syck;

has item_printer => ( is => "rw", isa => "CodeRef", lazy => 1, default => sub { \&_item_printer_default } );

__PACKAGE__->meta->make_immutable;
no Moose;

sub itemize {
    my ( $self, $results, $domain, $labels ) = @_;

    $labels ||= {};

    my $keys = [];
    my $msgs = [];
    $self->_walk($results, $labels, $domain, $keys, $msgs);

    @$msgs;
}

sub _item_printer_default {
    my ( $address, $label, $domain_name, $message ) = @_;
    sprintf("%s: %s", $label, $message);
}

sub _paths2label {
    my ( $self, $labels, @paths ) = @_;

    my @indexes = grep { m/^\d+$/ } @paths;
    my @digit   = map { $_+1 } @indexes;
    my $address = join(".", map { m/^\d+$/ ? '*' : $_ } @paths);

    sprintf($labels->{$address} || $address, @digit);
}

sub _walk {
    my ( $self, $results, $labels, $cur, $paths, $msgs ) = @_;

    if ( _INSTANCE($cur, "Data::Domain::Struct") ) {
        for my $f ( @{$cur->{-fields_list}} ) {
            push @$paths, $f;
            $self->_walk($results, $labels, $cur->{-fields}{$f}, $paths, $msgs);
            pop @$paths;
        }
    }
    elsif ( _INSTANCE($cur, "Data::Domain::List") ) {
        my $error_id = do {
            my $pos = $results;
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
                $self->_walk($results, $labels, $cur->{-all}{-fields}{$f}, $paths, $msgs);
                pop @$paths;
            }
        }
        elsif ( _ARRAY($error_id) ) {
            my $i = 0;
            for (@$error_id) {
                for my $f ( @{$cur->{-all}{-fields_list}} ) {
                    push @$paths, $i, $f;
                    $self->_walk($results, $labels, $cur->{-all}{-fields}{$f}, $paths, $msgs);
                    pop @$paths;
                    pop @$paths;
                }
                $i++;
            }
        }
    }
    elsif ( _INSTANCE($cur, "Data::Domain::All") ) {
        $self->_walk($results, $labels, $cur->{error_domain}, $paths, $msgs);
    }
    else {
        my @arrived;

        my $pos = $results;
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

        if (my $msg = $pos) {
            my $field = $self->_paths2label($labels, @arrived);

            my ($name, $message) = $msg =~ m/^(?:(\w+): )?(.*)$/;
            push @$msgs, $self->item_printer->(join(".", @arrived), $field, $name, $message);
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


--- !!perl/hash:Data::Domain::All
-domains:
  - !!perl/hash:Data::Domain::Struct
    -fields:
      username: !!perl/hash:Data::Domain::All
        -domains:
          - !!perl/hash:Data::Domain::String
            -max_length: 32
            -min_length: 4
          - !!perl/hash:Data::Domain::Code
            -coderefs:
              - !!perl/code: '{ "DUMMY" }'
            -messages:
              NOT_EXISTS: 登録されていません。
    -fields_list:
      - username
  - !!perl/hash:Data::Domain::Struct
    -fields:
      password: !!perl/hash:Data::Domain::All
        -domains:
          - !!perl/hash:Data::Domain::Code
            -coderefs:
              - !!perl/code: '{ "DUMMY" }'
            -messages:
              INVALID_PASSWORD: パスワードが違います。
    -fields_list:
      - password
