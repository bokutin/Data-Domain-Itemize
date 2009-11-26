use utf8;
use strict;
use warnings;
use Test::More 'no_plan';

use Data::Domain ':all';
use FindBin;
require "$FindBin::Bin/../t/lib/util.t";

use_ok("Data::Domain");

case1: {
    use_ok("Data::Domain::All", "All");

    my $domain = Struct( -fields => [
        num1 => All( Enum("AA", "BB"), Enum("BB", "CC") ),
    ] );

    ok(  defined $domain->inspect({num1=>"AA"}), 'case1');
    ok( !defined $domain->inspect({num1=>"BB"}), 'case1');
    ok(  defined $domain->inspect({num1=>"CC"}), 'case1');
    ok(  defined $domain->inspect({num1=>"DD"}), 'case1');
}
