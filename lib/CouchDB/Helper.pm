package CouchDB::Helper;

use warnings;
use strict;

use Cwd;

use CouchDB::Client;
use File::Slurp qw[slurp read_dir];

=head1 NAME

CouchDB::Helper - make developing with CouchDB easier

=cut

our $VERSION = '0.01';

use base 'Exporter';
our @EXPORT = qw[install_to_couchdb];

use File::stat;

sub data_for_database {
    my $topdir = shift;

    my %result;
    my $revtime = 0;
    my $datatime = 0;
    my @toplevel = read_dir($topdir . '/_design');

    foreach my $d (@toplevel) {
        my @files = read_dir($topdir . '/_design/' . $d);
        my $name  = '_design/' . $d;
        foreach my $f (@files) {
            my $path = $topdir . '/_design/' . $d . '/' . $f;
            if ($f eq '_rev') {
                $result{$name}{'_rev'} = slurp($path);
                $revtime = (stat($path))->mtime;
                chomp($result{$name}{'_rev'});
            } else {
                my @views = read_dir($path);
                foreach my $v (@views) {
                    foreach my $part (read_dir($path . '/' . $v)) {
                        if ($part =~ /\.js$/) {
                            $part =~ s/\.js$//;
                            $result{$name}{$f}{$v}{$part} =
                              slurp($path . '/' . $v . '/' . $part . '.js');
                              my $t = (stat($path . '/' . $v . '/' . $part . '.js'))->mtime;
                              $datatime = $t if $t > $datatime;
                        } else {
                            die
"Don't know what to do with non-JavaScript here: $part.";
                        }
                    }
                }
            }
        }
    }

    return (\%result, ($datatime > $revtime));
}

sub read_all {
    my $topdir = cwd();
    my %result;

    unless(-d $topdir . '/couchdb') {
        exit(0)
    }

    foreach my $db (read_dir($topdir . '/couchdb')) {
        my ($res, $do_upload) = data_for_database($topdir . '/couchdb/' . $db);
        $result{$db} = $res if $do_upload;
    }

    return \%result;
}

sub store_to_db {
    my ($conn, $dbname, $alldata) = @_;
    my $db = $conn->newDB($dbname);

    if (!$conn->dbExists($dbname)) {
        $db->create;
    }

    foreach my $view (keys %$alldata) {
        my $doc;
        my $data = $alldata->{$view};

        if (defined($data->{_rev}) and $data->{_rev}) {
            $doc = $db->newDoc($view, $data->{_rev})->retrieve;
            delete $data->{_rev};
            $doc->data($data);
            $doc->update;
        } else {
            delete $data->{_rev} if exists $data->{_rev};
            $doc = $db->newDoc($view, undef, $data);
            $doc->create;
        }
        print "Installed to " . $db->uriName . '/' . $doc->uriName . "\n";

        my $topdir   = cwd();
        my $filename = $topdir . '/couchdb/' . $dbname . '/' . $view . '/_rev';
        open my $fh, '>', $filename
          or die "Failed to open _rev file $filename: $!\n";
        print $fh $doc->rev;
        close $fh;
    }
}

sub install_to_couchdb {
    my $url = shift;
    my $res = read_all();

    my $conn = CouchDB::Client->new(uri => $url);
    die "Failed to connect to database.\n" unless $conn->testConnection;

    foreach my $db (keys %$res) {
        store_to_db($conn, $db, $res->{$db});
    }
}

=head1 SYNOPSIS

Build a CouchDB design document from a filestructure on disk and upload it to
a given server.

=head1 EXPORT

By default exports the function install_to_couchdb(). Since programs using
this module will typically consist of a single line calling that function,
exporting it by default seems reasonable.

=head1 USAGE

install_to_couchdb($url_to_couchdb);

=head1 AUTHOR

Calle Dybedahl, C<< <calle at init.se> >>

=head1 BUGS

Please report any bugs or feature requests at L<http://github.com/cdybedahl/CDBHelper/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CouchDB::Helper


You can also look for information at Github (url given above).

=head1 COPYRIGHT & LICENSE

Copyright 2010 Calle Dybedahl, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of CouchDB::Helper
