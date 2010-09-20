package CouchDB::Helper;

use warnings;
use strict;

use Cwd;

use CouchDB::Client;
use File::Slurp qw[slurp read_dir];

use Data::Dumper;

=head1 NAME

CouchDB::Helper - make developing with CouchDB easier

=cut

our $VERSION = '0.01';

use base 'Exporter';
our @EXPORT = qw[install_to_couchdb];

sub data_for_database {
    my $topdir = shift;
    
    my %result;
    my @toplevel = read_dir($topdir . '/_design');

    foreach my $d (@toplevel) {
        my @files = read_dir($topdir . '/_design/' . $d);
        my $name = '/_design/' . $d;
        foreach my $f (@files) {
            my $path = $topdir . '/_design/' . $d . '/' . $f;
            if ($f eq '_rev') {
                $result{$name}{'_rev'} = slurp($path);
                chomp($result{$name}{'_rev'});
            } else {
                my @views = read_dir($path);
                foreach my $v (@views) {
                    foreach my $part (read_dir($path . '/' . $v)) {
                        if ($part =~ /\.js$/) {
                            $part =~ s/\.js$//;
                            $result{$name}{$f}{$v}{$part} =
                              slurp($path . '/' . $v . '/' . $part . '.js');
                        } else {
                            die "Don't know what to do with non-JavaScript here: $part.";
                        }
                    }
                }
            }
        }
    }
    
    return \%result;
}

sub read_all {
    my $topdir = cwd();
    my %result;
    
    foreach my $db (read_dir($topdir . '/couchdb')) {
        $result{$db} = data_for_database($topdir . '/couchdb/' . $db)
    }

    return \%result;
}

sub install_to_couchdb {
    my $url = shift;
    my $res = read_all();
    print Dumper($res);
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
