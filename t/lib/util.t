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
    my ( $data, $expect, @args ) = @_;
    is_deeply( $data, $expect, @args ) or diag(_dump($data));
}

1;
