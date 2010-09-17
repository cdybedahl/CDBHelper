#!/opt/local/bin/perl

use strict;
use warnings;

use CouchDB::Helper;

my $dburl = shift(@ARGV);

die $dburl;