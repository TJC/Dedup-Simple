package Dedup::Databasey;
use 5.14.1;
use Moose::Role;
use Dedup::Schema;
require DBD::SQLite;

has 'database' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has 'db' => (
    is => 'rw',
    lazy => 1,
    default => sub { shift->db_connect },
);

sub db_connect {
    my $self = shift;
    return Dedup::Schema->connect('dbi:SQLite:dbname=' . $self->database);
}

1;
