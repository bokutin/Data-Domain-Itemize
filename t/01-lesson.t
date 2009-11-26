use utf8;
use strict;
use warnings;
use Test::More 'no_plan';

use Clone qw(clone);
use Data::Domain ':all';
use FindBin;
require "$FindBin::Bin/../t/lib/util.t";

use_ok("Data::Domain");

case1: {
    my $domain = Struct( -fields => [
        username => String,
        password => String( -messages => "入力してください。" ),
    ] );

    my $data = {
        username => undef,
        password => undef,
    };

    my $results  = $domain->inspect($data);

    my $expected = {
            password => "String: 入力してください。",
            username => "String: undefined data",
        };

    _is_deeply( $results, $expected, 'case1' );
}

case2: {
    my $Email = String(
                    -regex    => qr/^[-.\w]+\@[\w.]+$/,
                    -messages => {
                        SHOULD_MATCH => "Invalid email",
                    },
                );

    my $domain = Struct( -fields => [
        email1 => $Email,
        email2 => $Email,
    ] );

    my $data = {
        email1 => undef,
        email2 => 'foobar',
    };

    my $results  = $domain->inspect($data);

    my $expected = {
        email1 => "String: undefined data",
        email2 => "String: Invalid email",
    };

    _is_deeply( $results, $expected, 'case2' );
}

case3: {
    my $domain = Struct( -fields => [
        num1 => One_of( Enum("AA", "BB"), Enum("CC", "DD") ),
    ] );

    _is_deeply( $domain->inspect({num1=>"AA"}), undef, 'case3' );
    _is_deeply( $domain->inspect({num1=>"BB"}), undef, 'case3' );
    _is_deeply( $domain->inspect({num1=>"CC"}), undef, 'case3' );
    _is_deeply( $domain->inspect({num1=>"DD"}), undef, 'case3' );
    _is_deeply( $domain->inspect({num1=>"EE"}), {num1=>["Enum: not in enumeration list", "Enum: not in enumeration list"]}, 'case3' );
}
