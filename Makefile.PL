use inc::Module::Install;

name 'Data::Domain::Itemize';
all_from 'lib/Data/Domain/Itemize.pm';

requires 'Any::Moose';
requires 'Data::Domain';
requires 'Params::Util';
requires 'Try::Tiny';
requires 'namespace::autoclean'

#install_script glob('script/*.pl');
auto_install;
WriteAll;
