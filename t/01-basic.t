use utf8;
use strict;
use warnings;
use Test::More 'no_plan';
use Clone qw(clone);
use Data::Domain ':all';

use_ok("Data::Domain::Itemize");

my %ERROR2TEXT = (
    Generic => {
        UNDEFINED     => "undefined data",
        INVALID       => "invalid",
        TOO_SMALL     => "smaller than minimum %s",
        TOO_BIG       => "bigger than maximum %s",
        EXCLUSION_SET => "belongs to exclusion set",

        UNDEFINED => sub {
            my ( $field_text ) = @_;
            "${field_text}を入力してください。";
        },
        NOT_EXISTS => sub {
            my ( $field_text ) = @_;
            "${field_text}が見付かりませんでした。",
        },
    },
    Int => {
        INVALID => "正数で入力してください。",
    },
    Whatever => {
        MATCH_DEFINED => "data defined/undefined",
        MATCH_TRUE    => "data true/false",
        MATCH_ISA     => "is not a %s",
        MATCH_CAN     => "does not have method %s",
    },
    Num    => {INVALID => "invalid number",},
    Date   => {INVALID => "invalid date",},
    String => {
        TOO_SHORT        => "less than %d characters",
        TOO_LONG         => "more than %d characters",
        SHOULD_MATCH     => "should match %s",
        SHOULD_NOT_MATCH => "should not match %s",
    },
    Enum => {NOT_IN_LIST => "not in enumeration list",},
    List => {
        NOT_A_LIST => "is not an arrayref",
        TOO_SHORT  => "less than %d items",
        TOO_LONG   => "more than %d its",
        ANY        => "should have at least one %s",

        TOO_SHORT => sub {
            my ( $field_text ) = @_;
            "${field_text}が少なすぎます。";
        },
    },
    Struct => {
        NOT_A_HASH      => "is not a hashref",
        FORBIDDEN_FIELD => "contains forbidden field: %s"
    },
);

sub _dump {
    my $data = shift;

    if ( require YAML::Syck ) {
        no warnings 'once';
        local $YAML::Syck::ImplicitUnicode = 1;
        YAML::Syck::Dump($data);
    }
    elsif ( require Data::Dumper ) {
        Data::Dumper::Dumper($data);
    }
    else {
        explain($data);
    }
}

sub _is_deeply {
    my ( $data, $expect ) = @_;
    is_deeply( $data, $expect ) or diag(_dump($data));
}

sub _itemize {
    Data::Domain::Itemize->new( error2text => \%ERROR2TEXT, @_ )->itemize;
}

case1: {
    my $domain = Struct(
        user => Struct(
            username => String,
            password => String,
            retype   => sub {
                my $context = shift;
                if ( $context->{flat}{password} ) {
                    Enum( $context->{flat}{password} );
                }
                else {
                    Whatever;
                }
            },
        ),
        land => Struct(
            name   => String,
            kakaku => Int,
        ),
        images => List(
            -size => [1, 10],
            -all  => Struct(
                pathname => String,
            ),
        ),
    );

    my $data = {
        user => {
            username => undef,
            password => undef,
            retype   => undef,
        },
        land => {
            name   => undef,
            kakaku => undef,
        },
        images => [
        ],
    };

    my %field = (
        "user.username"     => "ユーザー名",
        "user.password"     => "パスワード",
        "land.name"         => "土地名",
        "land.kakaku"       => "価格",
        "images"            => "画像",
        "images.*.pathname" => "画像%dのpathname",
    );

    _is_deeply( [_itemize( domain => $domain, data => $data, field2text => \%field )],
        [
            "ユーザー名を入力してください。",
            "パスワードを入力してください。",
            "土地名を入力してください。",
            "価格を入力してください。",
            "画像が少なすぎます。",
        ] );
}

case2: {
    my $domain = Struct(
        user => Struct(
            username => String,
            password => String,
            retype   => sub {
                my $context = shift;
                if ( $context->{flat}{password} ) {
                    Enum( $context->{flat}{password} );
                }
                else {
                    Whatever;
                }
            },
        ),
        land => Struct(
            name   => String,
            kakaku => Int,
            latitude => Num(
                -messages => "半角数字で入力してください。",
            ),
        ),
        images => List(
            -size => [1, 10],
            -all  => Struct(
                pathname => String,
            ),
        ),
    );

    my $data = {
        user => {
            username => undef,
            password => undef,
            retype   => undef,
        },
        land => {
            name   => undef,
            kakaku => "abcdef",
        },
        images => [
        ],
    };

    my %field = (
        "user.username"     => "ユーザー名",
        "user.password"     => "パスワード",
        "land.name"         => "土地名",
        "land.kakaku"       => "価格",
        "land.latitude"     => "緯度",
        "images"            => "画像",
        "images.*.pathname" => "画像%dのpathname",
    );

    _is_deeply( [_itemize( domain => $domain, data => $data, field2text => \%field )],
        [
            "ユーザー名を入力してください。",
            "パスワードを入力してください。",
            "土地名を入力してください。",
            "« 価格 » 正数で入力してください。",
            "« 緯度 » 半角数字で入力してください。",
            "画像が少なすぎます。",
        ] );
}

case3: {
    my $domain = Struct(
        user => Struct(
            username => String,
            password => String,
            retype   => sub {
                my $context = shift;
                if ( $context->{flat}{password} ) {
                    Enum( $context->{flat}{password} );
                }
                else {
                    Whatever;
                }
            },
        ),
        land => Struct(
            name   => String,
            kakaku => Int,
            latitude => Num(
                -name => "LatLan",
                -messages => "INVALID",
            ),
        ),
        images => List(
            -size => [1, 10],
            -all  => Struct(
                pathname => String,
            ),
        ),
    );

    my $error2text = clone(\%ERROR2TEXT);
    $error2text->{LatLan}{INVALID} = sub {
        my $field_text = shift;
        "${field_text}を半角数字で入力してください。";
    };

    my $data = {
        user => {
            username => undef,
            password => undef,
            retype   => undef,
        },
        land => {
            name   => undef,
            kakaku => "abcdef",
        },
        images => [
            { pathname => "a.png", },
            { pathname => undef,   },
            { pathname => "c.png", },
        ],
    };

    my %field = (
        "user.username"     => "ユーザー名",
        "user.password"     => "パスワード",
        "land.name"         => "土地名",
        "land.kakaku"       => "価格",
        "land.latitude"     => "緯度",
        "images"            => "画像",
        "images.*.pathname" => "画像%dのpathname",
    );

    _is_deeply( [_itemize( domain => $domain, data => $data, field2text => \%field, error2text => $error2text )],
        [
            "ユーザー名を入力してください。",
            "パスワードを入力してください。",
            "土地名を入力してください。",
            "« 価格 » 正数で入力してください。",
            "緯度を半角数字で入力してください。",
            #"画像2がエラーです。",
            "画像2のpathnameを入力してください。",
        ] );
}

use_ok("Data::Domain::Code");

case4: {
    my %db = (
        100 => 1,
        200 => 1,
        300 => 1,
    );

    my $check_exists = sub {
        my ( $context, $data ) = @_;

        no warnings 'uninitialized';
        if ( length and m/^\d+$/ and $db{$data} ) {
            return;
        }
        else {
            return "NOT_EXISTS";
        }
    };

    my $domain = Struct(
        id1 => Empty,
        id2 => sub { Empty },
        id3 => sub {
            my $context = shift;
            $_ = $context->{flat}{id3};
            no warnings 'uninitialized';

            if ( length and m/^\d+$/ and $db{$_} ) {
                Whatever;
            }
            else {
                Empty(-messages=>"NOT_EXISTS");
            }
        },
        id4 => Code($check_exists),
        id5 => Code($check_exists),
    );

    my $data = {
        id1 => 10,
        id2 => 10,
        id3 => 10,
        id4 => 100,
        id5 => 101,
    };

    my %field = (
    );

    #warn _dump($domain);
    #warn _dump( $domain->inspect($data) );
    #die;
    _is_deeply( [_itemize( domain => $domain, data => $data, field2text => \%field )],
        [
            "« id1 » invalid",
            "« id2 » invalid",
            "id3が見付かりませんでした。",
            "id5が見付かりませんでした。",
        ] );
}

case5: {
    my $domain = Struct(
        num1 => Code( sub { return ("INVALID", "Generic") } ),
        num2 => Code( sub { return ("INVALID", "Int") } ),
    );

    my $data = {
        num1 => "foo",
        num2 => "foo",
    };

    my %field = (
    );

    _is_deeply( [_itemize( domain => $domain, data => $data, field2text => \%field )],
        [
            "« num1 » invalid",
            "« num2 » 正数で入力してください。",
        ] );
}
