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
use File::Slurp;
use Cwd;

sub get_content_of {
    my $name = shift;
    my $stat = stat($name);

    if (-f $name) {
        return {
            stat    => $stat,
            content => scalar(read_file($name)),
            type    => 'file',
        };
    } elsif (-d $name) {
        my %res;
        my $cwd = cwd();
        opendir my $d, $name or die "$name: $!";
        $res{stat} = $stat;
        $res{type} = 'dir';
        chdir($name);
        foreach my $f (grep { $_ ne '.' and $_ ne '..' } readdir $d) {
            $res{content}{$f} = get_content_of($f);
        }
        chdir($cwd);
        return \%res;
    } else {
        return {
            stat    => $stat,
            content => '<non-handled file type>',
            type    => 'other',
        };
    }
}

sub max_mtime {
    my $tree = shift;
    my $max  = 0;

    foreach my $t (keys %$tree) {
        next if $t eq '_rev';
        if ($tree->{$t}{type} eq 'file') {
            $max = $tree->{$t}{stat}->mtime if $tree->{$t}{stat}->mtime > $max;
        } elsif ($tree->{$t}{type} eq 'dir') {
            my $tmp = max_mtime($tree->{$t}{content});
            $max = $tmp if $tmp > $max;
        }
    }

    return $max;
}

sub prune_tree {
    my $node = shift;

    if (!ref($node)) {
        return $node;
    } elsif (ref($node) eq 'HASH') {
        my %res;

        while (my ($name, $tree) = each %$node) {
            $name =~ s/\.js$//;
            $res{$name} = prune_tree($tree->{content});
        }
        return \%res;
    } else {
        die "Strange node type: " . ref($node);
    }
}

sub build_design_docs {
    my $dir = shift || 'couchdb';
    my $tree = get_content_of($dir);
    my @ddocs;
    my @res;

    while (my ($database, $subtree) = each %{ $tree->{content} }) {
        while (my ($docname, $doctree) =
            each %{ $subtree->{content}{_design}{content} })
        {
            push @ddocs,
              {
                database => $database,
                id       => '_design/' . $docname,
                tree     => $doctree->{content}
              };
        }
    }

    foreach my $doc (@ddocs) {
        if (!($doc->{tree}{_rev})
            or max_mtime($doc->{tree}) > $doc->{tree}{_rev}{stat}->mtime)
        {
            push @res,
              {
                database => $doc->{database},
                id       => $doc->{id},
                content  => prune_tree($doc->{tree})
              };
        }
    }

    return @res;
}

sub store_to_db {
    my ($conn, $doc) = @_;
    my $dbname = $doc->{database};
    my $id     = $doc->{id};
    my $db     = $conn->newDB($dbname);

    if (!$conn->dbExists($dbname)) {
        $db->create;
    }

    my $dbdoc = $db->newDoc($id, $doc->{content}{_rev});
    if ($db->docExists($id)) {
        $dbdoc->retrieve;
    } else {
        $dbdoc->create;
    }
    $dbdoc->data($doc->{content});
    print "Uploading " . $dbname . '/' . $id . "\n";
    $dbdoc->update;

    my $topdir   = cwd();
    my $filename = $topdir . '/couchdb/' . $dbname . '/' . $id . '/_rev';
    open my $fh, '>', $filename
      or die "Failed to open _rev file $filename: $!\n";
    print $fh $dbdoc->rev;
    close $fh;
}

sub install_to_couchdb {
    my $url      = shift || $ENV{COUCHDB_URL} || 'http://127.0.0.1:5984';
    my $username = shift || $ENV{COUCHDB_USERNAME};
    my $password = shift || $ENV{COUCHDB_PASSWORD};
    my $realm    = shift || $ENV{COUCHDB_REALM};
    my @ddocs = build_design_docs();

    my $conn = CouchDB::Client->new(
        uri      => $url,
        username => $username,
        password => $password,
        realm    => $realm
    );
    die "Failed to connect to database.\n" unless $conn->testConnection;

    foreach my $doc (@ddocs) {
        store_to_db($conn, $doc);
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

install_to_couchdb([$url_to_couchdb, [$username, $password, [$realm]]]);

All of the parameters are optional. If none are given, the environment
contents of the variables COUCHDB_URL, COUCHDB_USERNAME, COUCHDB_PASSWORD and
COUCHDB_REALM will be used as default values. If any of them are not set,
COUCHDB_URL will default to 'http://127.0.0.1:5984/' and the others to
nothing.

You only ever need to specify the realm if you're talking to a CouchDB
instance where the HTTP Basic Auth realm has been set to something other than
the standard value.

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
