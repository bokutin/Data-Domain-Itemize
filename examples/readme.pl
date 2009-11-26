use utf8;
use strict;
use Data::Domain ':all';
use Data::Domain::Itemize;
use YAML::Syck;
$YAML::Syck::ImplicitUnicode = 1;

my $domain = Struct(
    user => Struct(
        username => String,
        password => String,
    ),
    links => List(
        -all => Struct(
            title => String,
            uri   => String,
        ),
        -size => [0, 10]
    ),
);

my $input = {
    user => {
        username => "foobar",
        password => undef,
    },
    links => [
        { title => "bokut.in", uri => "http://bokut.in/mt/"     } ,
        { title => "Google",   uri => undef                     } ,
        { title => "CPAN",     uri => "http://search.cpan.org/" } ,
    ],
};


my $results = $domain->inspect($input);
#warn Dump($results);
#--- 
#links: 
#  - ~
#  - 
#    uri: "String: undefined data"
#  - ~
#user: 
#  password: "String: undefined data"


my %label = (
    'user.password' => "パスワード",
    'links.*.uri'   => "%d個目のリンクのURI",
);
my @items1 = Data::Domain::Itemize->new->itemize($results, $domain, \%label);
#warn Dump(\@items1);
#--- 
#- "パスワード: undefined data"
#- "2個目のリンクのURI: undefined data"


my $custom = sub {
    my ( $address, $label, $domain_name, $message ) = @_;
    sprintf("« %s » %s", $label, $message);
};
Data::Domain->messages(
    {
        String => {
            UNDEFINED => "入力してください。",
        },
    },
);
my $results2 = $domain->inspect($input);
my @items2   = Data::Domain::Itemize->new(item_printer=>$custom)->itemize($results2, $domain, \%label);
#warn Dump(\@items2);
#--- 
#- « パスワード » 入力してください。
#- « 2個目のリンクのURI » 入力してください。
