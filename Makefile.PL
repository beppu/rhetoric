use inc::Module::Install;

name 'Rhetoric';
all_from 'lib/Rhetoric.pm';

requires 'aliased'             => 0;
requires 'common::sense'       => 0;
requires 'Squatting'           => '0.70';
requires 'File::Find::Rule'    => 0;
requires 'File::Which'         => 0;
requires 'Pod::Simple::Search' => 0;
requires 'IO::All'             => 0;

install_script 'bin/rh';
install_script 'bin/rh-init';
install_script 'bin/rh-export';

WriteAll;
