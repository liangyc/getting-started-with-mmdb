#!/usr/bin/env perl

use strict;
use warnings;
use feature qw( say );
use Text::CSV;
use MaxMind::DB::Writer::Tree;
use Net::Works::Network;
use open ':std', ':encoding(UTF-8)';

my $csv_file = $ARGV[0] or die "Need to get CSV file on the command line\n";
my $mmdb_file = $ARGV[1] or die "Need to get mmdb out file path on the command line\n";

print "$csv_file\n";
print "$mmdb_file\n";

my $csv = Text::CSV->new({ sep_char => ',' });
open(my $csvdata, '<:encoding(utf8)', $csv_file) or die "Could not open '$csv_file' $!\n";

# Your top level data structure will always be a map (hash).  The MMDB format
# is strongly typed.  Describe your data types here.
# See https://metacpan.org/pod/MaxMind::DB::Writer::Tree#DATA-TYPES

#my %types = (
#    cityid      => 'uint32',
    #country      => 'utf8_string',
    #country_code => 'utf8_string',
    #region       => 'utf8_string',
    #city         => 'utf8_string',
#);

my %types = (
    environments => [ 'array', 'utf8_string' ],
    expires      => 'uint32',
    name         => 'utf8_string',
);

my $tree = MaxMind::DB::Writer::Tree->new(

    # "database_type" is some arbitrary string describing the database.  At
    # MaxMind we use strings like 'GeoIP2-City', 'GeoIP2-Country', etc.
    database_type => 'My-IP-Data',

    # "description" is a hashref where the keys are language names and the
    # values are descriptions of the database in that language.
    description =>
        { en => 'My database of IP data', fr => q{Mon Data d'IP}, },

    # "ip_version" can be either 4 or 6
    ip_version => 4,

    # add a callback to validate data going in to the database
    map_key_type_callback => sub { $types{ $_[0] } },

    # "record_size" is the record size in bits.  Either 24, 28 or 32.
    record_size => 32,

    merge_strategy => "toplevel",
);

my $i=0;

while (my $line = <$csvdata>) {
    $i++;

    if($i % 100000 == 0) {
        print "$i\n";
    }

    chomp $line;
 
    if ($csv->parse($line)) {
        my @fields = $csv->fields();
        #print "$fields[0]\t$fields[1]\t$fields[2]\t$fields[3]\t$fields[4]\t$fields[5]\n";
        my $address = "$fields[0]/32";
        #print "address is: $address\n";
        my %ipgeo = (
            #country         => $fields[1],
            #country_code    => $fields[2],
            #region          => $fields[3],
            #city            => $fields[4],
            cityid         => 321321
        );

        my %ipgeo2 = (
        environments => [ 'development', 'staging', 'production' ],
        expires      => 86400,
        name         => 'Jane',
    ),

        #print "ipgeo map is: ";
        #print %ipgeo;
        #print "\n";
        my $network = Net::Works::Network->new_from_string( string => '123.125.71.29/32' ); 
        print "network is: $network\n";
        #my $ipgeo = \%ipgeo;
        $tree->insert_network( $network, \%ipgeo2 );
    } else {
        warn "Line could not be parsed: $line\n";
    }
}


# Write the database to disk.
open(my $fh, '>:raw', $mmdb_file);
$tree->write_tree( $fh );
close $fh;

say "$mmdb_file has now been created";
