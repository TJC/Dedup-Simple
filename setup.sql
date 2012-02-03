
create table files (
  id integer primary key,
  checksum varchar(64),
  path text,
  mtime integer,
  size  integer
);

create index files_checksum_idx ON files(checksum);
create index files_path_idx ON files(checksum);
