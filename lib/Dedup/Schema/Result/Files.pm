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

create table files (
  id integer primary key,
  checksum varchar(64),
  path text,
  mtime integer,
  size  integer
);

create index files_checksum_idx ON files(checksum);
create index files_path_idx ON files(checksum);

=cut

