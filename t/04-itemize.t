use utf8;
use strict;
use warnings;
use Test::More 'no_plan';
use Clone qw(clone);
use Data::Domain ':all';
use FindBin;
require "$FindBin::Bin/../t/lib/util.t";

use_ok("Data::Domain::Itemize");

my %ERROR2TEXT = (
    Generic => {
        UNDEFINED     => "undefined data",
        INVALID       => "invalid",
        TOO_SMALL     => "smaller than minimum %s",
        TOO_BIG       => "bigger than maximum %s",
        EXCLUSION_SET => "belongs to exclusion set",

        UNDEFINED  => "入力してください。",
        NOT_EXISTS => "見付かりませんでした。",
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

        TOO_SHORT => "少なすぎます。",
    },
    Struct => {
        NOT_A_HASH      => "is not a hashref",
        FORBIDDEN_FIELD => "contains forbidden field: %s"
    },
);

Data::Domain->messages(\%ERROR2TEXT);

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
        photos => List(
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
        photos => [
            { pathname => "foo" },
            { pathname => undef },
            { pathname => "bar" },
        ],
    };

    my %label = (
        "user.username"     => "ユーザー名",
        "user.password"     => "パスワード",
        "land.name"         => "土地名",
        "land.kakaku"       => "価格",
        "images"            => "画像",
        "images.*.pathname" => "画像%dのpathname",
        "photos"            => "写真",
        "photos.*.pathname" => "写真%dのpathname",
    );

    my $results = $domain->inspect($data);
    my @items    = Data::Domain::Itemize->new->itemize( $results, $domain, \%label );
    my $expected = [
        "ユーザー名: 入力してください。",
        "パスワード: 入力してください。",
        "土地名: 入力してください。",
        "価格: 入力してください。",
        "画像: 少なすぎます。",
        "写真2のpathname: 入力してください。",
    ];

    _is_deeply( \@items, $expected, 'case1' );

    #warn _dump($results);
    #warn _dump(\@items);
}

login: {
    use_ok("Data::Domain::All", "All");
    use_ok("Data::Domain::Code", "Code");

    my $domain1 = Struct(
        username => String(
            -messages => "ユーザー名を入力してください。",
        ),
        password => String(
            -messages => "パスワードを入力してください。",
        ),
    );
    my $domain2 = Struct(
        password => Code(
            -messages => "パスワードが間違っています。",
            sub {
                my ( $context, $data ) = @_;
                return "INVALID";
            }
        ),
    );
    my $domain = All($domain1, $domain2);

    {
        my $results  = $domain->inspect({});
        my @items    = Data::Domain::Itemize->new()->itemize( $results, $domain );
        my $expected = [
            "username: ユーザー名を入力してください。",
            "password: パスワードを入力してください。",
        ];

        _is_deeply( \@items, $expected, 'case2' );
    }

    my $item_printer = sub {
        my ( $address, $label, $domain_name, $message ) = @_;
        sprintf("%s", $message);
    };

    {
        my $results  = $domain->inspect({});
        my @items    = Data::Domain::Itemize->new(item_printer=>$item_printer)->itemize( $results, $domain );
        my $expected = [
            "ユーザー名を入力してください。",
            "パスワードを入力してください。",
        ];

        _is_deeply( \@items, $expected, 'case2' );
    }

    {
        my $results  = $domain->inspect({username=>"foo",password=>"bar"});
        my @items    = Data::Domain::Itemize->new(item_printer=>$item_printer)->itemize( $results, $domain );
        my $expected = [
            "パスワードが間違っています。",
        ];

        _is_deeply( \@items, $expected, 'case2' );
    }

    #warn _dump($results);
    #warn _dump(\@items);
}
