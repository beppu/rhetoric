use inc::Module::Install;

name 'Rhetoric';
all_from 'lib/Rhetoric.pm';

requires 'aliased'                    => 0;
requires 'common::sense'              => 0;
requires 'Squatting'                  => '0.80';
requires 'File::Find::Rule'           => 0;
requires 'File::Path::Tiny'           => 0;
requires 'File::Which'                => 0;
requires 'Pod::Simple'                => 0;
requires 'IO::All'                    => 0;
requires 'Memoize'                    => 0;
requires 'Method::Signatures::Simple' => 0;
requires 'CGI'                        => '1.30';

install_script 'bin/rh';
install_script 'bin/rh-init';
install_script 'bin/rh-export';

install_share 'share';

WriteAll;
