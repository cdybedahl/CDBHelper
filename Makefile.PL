use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CouchDB::Helper',
    AUTHOR              => 'Calle Dybedahl <calle@init.se>',
    VERSION_FROM        => 'lib/CouchDB/Helper.pm',
    ABSTRACT_FROM       => 'lib/CouchDB/Helper.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {'couchdb_load.pl' => 'http://127.0.0.1:5984/testdb'},
    PREREQ_PM => {
        'Test::More' => 0,
        'CouchDB::Client' => 0.09,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CouchDB-Helper-*' },
);
