#!/usr/bin/env perl
use 5.14.1;
use warnings;
use lib 'lib';
use Dedup::Build;

my $builder = Dedup::Build->new(
    database => 'checksums.db',
);

$builder->run('root');
