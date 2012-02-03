use inc::Module::Install;

name     'Dedup-Simple';
all_from 'lib/Dedup/Simple.pm';
author   q{Toby Corkindale <tjc@wintrmute.net>};
license  'perl';

build_requires 'Test::More';
requires 'Try::Tiny';
requires 'Moose';
requires 'DBIx::Class';
requires 'Digest::SHA';
requires 'File::Find';
requires 'autodie';

WriteAll;

