package Dedup::Schema::Result::Files;
use 5.14.1;
use warnings;
use parent 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('files');
__PACKAGE__->add_columns(
    qw(id checksum path mtime size)
);
__PACKAGE__->set_primary_key("id");

1;

=head1 SQL

See setup.sql

=cut

