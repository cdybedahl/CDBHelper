#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CouchDB::Helper' );
}

diag( "Testing CouchDB::Helper $CouchDB::Helper::VERSION, Perl $], $^X" );
