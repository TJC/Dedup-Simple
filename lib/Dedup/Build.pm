package Dedup::Build;
use 5.14.1;
use Moose;
use Dedup::Schema;
require DBD::SQLite;
use Digest::SHA qw(sha1_hex);
use IO::File;
use File::Find;
use autodie;

has 'database' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has 'CHUNK_SIZE' => (
    is => 'ro',
    isa => 'Int',
    default => (64*1024),
);

has 'db' => (
    is => 'rw',
    lazy => 1,
    default => sub { shift->db_connect },
);

sub run {
    my ($self, $root_dir) = @_;

    find(
        {
            wanted => sub {
                $self->process_file($File::Find::name)
            },
            no_chdir => 1
        },
        $root_dir
    );
}

# Given a filename, return a "short" checksum, based on the first and last
# 64kbytes.
sub checksum_file_short {
    my ($self, $filename) = @_;

    unless (-f $filename) {
        warn "Not a regular file: $filename\n";
        return;
    }

    unless (-e $filename) {
        warn "Does not exist: $filename\n";
        return;
    }

    my $size = -s $filename;
    unless ($size > 8192) {
        warn "Skipping tiny file: $filename\n";
        return;
    }

    my $digest = Digest::SHA->new('sha1');

    if ($size < $self->CHUNK_SIZE * 2) {
        $digest->addfile($filename);
        return $digest->b64digest;
    }

    my $buf;

    my $fh = IO::File->new($filename, "r");
    $fh->binmode(1);

    $fh->sysseek(0, SEEK_SET);
    $fh->sysread($buf, $self->CHUNK_SIZE);
    $digest->add($buf);
    $fh->sysseek(-$self->CHUNK_SIZE, SEEK_END);
    $fh->sysread($buf, $self->CHUNK_SIZE);
    $digest->add($buf);

    $fh->close;

    return $digest->b64digest;
}

sub process_file {
    my ($self, $file) = @_;
    my @stats = stat $file;
    my $mtime = $stats[9];
    my $size = $stats[7];

    my $record = $self->db->resultset('Files')->search({ path => $file })->next;
    if ($record and $record->mtime == $mtime and $record->size == $size) {
        warn "File already in DB with good size & mtime.\n";
        return;
    }

    my $checksum = $self->checksum_file_short($file);
    return unless defined $checksum;
    say "$checksum\t$file";

    if ($record) {
        $record->update(
            {
                mtime => $mtime,
                size => $size,
                checksum => $checksum,
            }
        );
    }
    else {
        $self->db->resultset('Files')->create(
            {
                path => $file,
                mtime => $mtime,
                size => $size,
                checksum => $checksum,
            }
        );
    }
}

sub db_connect {
    my $self = shift;
    return Dedup::Schema->connect('dbi:SQLite:dbname=' . $self->database);
}


1;
