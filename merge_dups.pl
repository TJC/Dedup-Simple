#!/usr/bin/env perl
use 5.14.1;
use warnings;
use lib 'lib';
use Dedup::Merge;

Dedup::Merge->new(
    database => 'checksums.db',
    testmode => 1,
)->go;

