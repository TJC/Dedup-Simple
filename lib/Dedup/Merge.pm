package Dedup::Merge;
use 5.14.1;
use Moose;
use Dedup::Schema;
require DBD::SQLite;
use IO::File;
use autodie;
use IPC::Run qw(run);
with 'Dedup::Databasey';

has 'testmode' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

sub go {
    my ($self) = @_;

    my $q = $self->db->storage->dbh->prepare(qq{
        select * from files a
        where exists (
          select id from files b
          where a.checksum = b.checksum and a.id <> b.id
        )
        order by checksum
    });
    $q->execute;

    my $checksum;
    my @files;
    while (my $row = $q->fetchrow_hashref) {
        if (length($checksum) and $checksum ne $row->{checksum}) {
            $self->process(@files);
            $checksum = '';
            @files = ();
        }
        $checksum = $row->{checksum};
        push @files, $row->{path};
    }
    $self->process(@files);
}

sub process {
    my ($self, @candidates) = @_;

    # warn "In process(" . join(', ', @candidates) . ")\n";

    # Only check files that aren't already hardlinked together..
    my @files = grep {
        my @stats = stat $_;
        $stats[3] == 1;
    } @candidates;

    # warn "selected files are: " . join(', ', @files) . "\n";

    # TODO: Need to avoid repeated comparisons here.
    my %seen;
    while (my $file = pop @files) {
        for my $other (@candidates) {
            next if $seen{$other . $file};
            $seen{$file . $other} = 1;
            $self->full_compare($file, $other);
        }
    }
}

sub full_compare {
    my ($self, $file, $other) = @_;
    return() if ($file eq $other); # don't compare identical paths

    # warn "Comparing $file with $other\n";
    return unless run('/usr/bin/cmp', '--silent', $file, $other);

    my $size = (-s $file);
    say "$size\t$file\t$other";
    return if $self->testmode;
    unlink($file);
    link($other, $file);
}

1;

