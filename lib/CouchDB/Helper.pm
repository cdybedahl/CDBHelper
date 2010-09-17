package CouchDB::Helper;

use warnings;
use strict;

=head1 NAME

CouchDB::Helper - make developing with CouchDB easier

=cut

our $VERSION = '0.01';

use base 'Exporter';
our @EXPORT = qw[install_to_couchdb];

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

1; # End of CouchDB::Helper
