use inc::Module::Install;

name 'Data::Domain::Itemize';
all_from 'lib/Data/Domain/Itemize.pm';

requires 'Data::Domain';
requires 'Moose';
requires 'Params::Util';
requires 'Try::Tiny';
requires 'namespace::autoclean'

#install_script glob('script/*.pl');
auto_install;
WriteAll;
