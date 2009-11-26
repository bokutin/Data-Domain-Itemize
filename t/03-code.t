use utf8;
use strict;
use warnings;
use Test::More 'no_plan';

use Clone qw(clone);
use Data::Domain ':all';
use FindBin;
require "$FindBin::Bin/../t/lib/util.t";

use_ok("Data::Domain::Code", 'Code');

my %ERROR2TEXT = (
    Generic => {
        UNDEFINED     => "undefined data",
        INVALID       => "invalid",
        TOO_SMALL     => "smaller than minimum %s",
        TOO_BIG       => "bigger than maximum %s",
        EXCLUSION_SET => "belongs to exclusion set",

        NOT_EXISTS    => "見付かりませんでした。",
    },
    Code => {
        NOT_A_EMAIL => "メールアドレスを正しく入力してください。",
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
    },
    Struct => {
        NOT_A_HASH      => "is not a hashref",
        FORBIDDEN_FIELD => "contains forbidden field: %s"
    },
);

Data::Domain->messages(\%ERROR2TEXT);

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

    my $results = $domain->inspect($data);

    my $expected = {
        id1 => "Empty: invalid",
        id2 => "Empty: invalid",
        id3 => "Empty: NOT_EXISTS",
        id5 => "Code: 見付かりませんでした。",
    };

    _is_deeply( $results, $expected, 'case4' );
}

case5: {
    my $Email = Code( sub {
            my ( $context, $data ) = @_;

            use Email::Valid::Loose;
            my $addr     = $data;
            my $is_valid = Email::Valid::Loose->address($addr);

            if ($is_valid) {
                return;
            }
            else {
                return "NOT_A_EMAIL";
            }
        });

    my $domain = Struct(
        email1 => $Email,
        email2 => $Email,
        email3 => $Email,
    );

    my $data = {
        email1 => undef,
        email2 => 'bokutin',
        email3 => 'bokutin@bokut.in',
    };

    my $results = $domain->inspect($data);

    my $expected = {
        email1 => "Code: undefined data",
        email2 => "Code: メールアドレスを正しく入力してください。",
    };

    _is_deeply( $results, $expected, 'case5' );
}

case5: {
    my $domain = Struct(
        num1 => Code( -messages => { INVALID100 => 'invalid100' }, sub { return ("INVALID100") } ),
    );

    my $data = {
        num1 => "foo",
    };

    my $results = $domain->inspect($data);

    my $expected = {
        num1 => "Code: invalid100",
    };

    _is_deeply( $results, $expected, 'case5' );
}

case6: {
    use_ok("Data::Domain::All", "All");

    my %db_user = ( foobar => 1 );

    my $domain = Struct(
        username => All(
            String( -min_length => 4, -max_length => 32 ),
            Code(
                -messages => {
                    EXISTS => "既に登録されています。",
                },
                sub {
                    my ( $context, $data ) = @_;
                    $db_user{$data} ? "EXISTS" : undef;
                }
            ),
        ),
    );

    _is_deeply(
        $domain->inspect({username=>undef}),
        {
            username => "All: undefined data",
        },
        'case6',
    );

    _is_deeply(
        $domain->inspect({username=>"a"}),
        {
            username => "String: less than 4 characters",
        },
        'case6',
    );

    _is_deeply(
        $domain->inspect({username=>"foobar"}),
        {
            username => "Code: 既に登録されています。",
        },
        'case6',
    );

    _is_deeply(
        $domain->inspect({username=>"foobar2"}),
        undef,
        'case6',
    );
}


case_login: {
    use_ok("Data::Domain::All", "All");

    my %db_user = ( foobar => 1 );

    my $Username = 
            All(
                String( -min_length => 4, -max_length => 32 ),
                Code(
                    -messages => {
                        NOT_EXISTS => "登録されていません。",
                    },
                    sub {
                        my ( $context, $data ) = @_;
                        $db_user{$data} ? undef : "NOT_EXISTS";
                    },
                ),
            );

    my $domain = Struct(
        -fields => [
            username => $Username,
            password => All(
                Code(
                    -messages => { INVALID_PASSWORD => "パスワードが違います。" },
                    sub {
                        my ( $context, $data ) = @_;

                        if ( !$Username->inspect($context->{root}{username}) ) {
                            #warn _dump($context);
                            return "INVALID_PASSWORD";
                        }
                        else {
                            return;
                        }
                    },
                ),
            ),
        ],
    );

    _is_deeply(
        $domain->inspect({username=>undef}),
        {
            username => "All: undefined data",
            password => "All: undefined data",
        },
        'case_login',
    );

    _is_deeply(
        $domain->inspect({username=>'a'}),
        {
            username => "String: less than 4 characters",
            password => "All: undefined data",
        },
        'case_login',
    );

    _is_deeply(
        $domain->inspect({username=>'foobar2'}),
        {
            username => "Code: 登録されていません。",
            password => "All: undefined data",
        },
        'case_login',
    );

    _is_deeply(
        $domain->inspect({username=>'foobar'}),
        {
            password => "All: undefined data",
        },
        'case_login',
    );

    _is_deeply(
        $domain->inspect({username=>'foobar',password=>"aaa"}),
        {
            password => "Code: パスワードが違います。",
        },
        'case_login',
    );

    _is_deeply(
        $domain->inspect({password=>"aaa"}),
        {
            username => "All: undefined data",
        },
        'case_login',
    );

    _is_deeply(
        $domain->inspect({username=>'foobar2',password=>'aaa'}),
        {
            username => "Code: 登録されていません。",
        },
        'case_login',
    );

}

case_login2: {
    use_ok("Data::Domain::All", "All");

    my %db_user = ( foobar => 1 );

    my $domain1 = Struct(
        -fields => [
            username => All(
                String( -min_length => 4, -max_length => 32 ),
                Code(
                    -messages => {
                        NOT_EXISTS => "登録されていません。",
                    },
                    sub {
                        my ( $context, $data ) = @_;
                        $db_user{$data} ? undef : "NOT_EXISTS";
                    },
                ),
            ),
        ],
    );
    my $domain2 = Struct(
        -fields => [
            password => All(
                Code(
                    -messages => { INVALID_PASSWORD => "パスワードが違います。" },
                    sub {
                        my ( $context, $data ) = @_;
                        return "INVALID_PASSWORD";
                    },
                ),
            ),
        ],
    );

    my $domain = All($domain1, $domain2);

    #warn _dump($domain);

    _is_deeply(
        $domain->inspect({username=>undef}),
        {
            username => "All: undefined data",
        },
        'case_login2',
    );

    _is_deeply(
        $domain->inspect({username=>'a'}),
        {
            username => "String: less than 4 characters",
        },
        'case_login2',
    );

    _is_deeply(
        $domain->inspect({username=>'foobar2'}),
        {
            username => "Code: 登録されていません。",
        },
        'case_login2',
    );

    _is_deeply(
        $domain->inspect({username=>'foobar'}),
        {
            password => "All: undefined data",
        },
        'case_login2',
    );

    _is_deeply(
        $domain->inspect({username=>'foobar',password=>"aaa"}),
        {
            password => "Code: パスワードが違います。",
        },
        'case_login2',
    );

    _is_deeply(
        $domain->inspect({password=>"aaa"}),
        {
            username => "All: undefined data",
        },
        'case_login2',
    );

    _is_deeply(
        $domain->inspect({username=>'foobar2',password=>'aaa'}),
        {
            username => "Code: 登録されていません。",
        },
        'case_login2',
    );

}

