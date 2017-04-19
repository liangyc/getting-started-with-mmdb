#!/usr/bin/env perl

use strict;
use warnings;
use feature qw( say );

use Data::Printer;
use MaxMind::DB::Reader;
use Net::Works::Address;
use MaxMind::DB::Writer::Tree;

my $csv_file = $ARGV[0];
my $mmdb_file = $ARGV[1] or die "Need to get mmdb out file path on the command line\n";

print "$csv_file\n";
print "$mmdb_file\n";


my $reader = MaxMind::DB::Reader->new( file => $csv_file );

my %types = (
    geoname_id => 'uint32',
    city_name =>

);

my $tree = MaxMind::DB::Writer::Tree->new(

    # "database_type" is some arbitrary string describing the database.  At
    # MaxMind we use strings like 'GeoIP2-City', 'GeoIP2-Country', etc.
    database_type => 'My-IP-Data',

    # "description" is a hashref where the keys are language names and the
    # values are descriptions of the database in that language.
    description =>
        { en => 'My database of IP data' },

    # "ip_version" can be either 4 or 6
    ip_version => 6,

    # add a callback to validate data going in to the database
    map_key_type_callback => sub { $types{ $_[0] } },

    # "record_size" is the record size in bits.  Either 24, 28 or 32.
    record_size => 28,

    merge_strategy => "none",
);

my $counter = 0;
my $noCity = 0;
my $nodeCounter = 0; 

my $treeMeta = $reader->metadata();
my @keys = keys %$treeMeta;
my @values = values%$treeMeta;
print "@keys\n";
print "@values\n";
print "%$treeMeta\n";

$reader->iterate_search_tree(
    sub {
        my $ip_as_integer = shift;
        my $mask_length   = shift;
        my $data          = shift;

        #my $ipv4_mask = $mask_length - 96;
        
        if ( $data->{'city'} and $data->{'country'}{'iso_code'} eq 'CN') {
        	my $address = Net::Works::Address->new_from_integer(integer => $ip_as_integer); #->as_ipv4_string;

        	my %idHash = (
        		geoname_id => $data->{'city'}{'geoname_id'},
        		);

        	$tree->insert_network("$address/$mask_length", \%idHash );
        	#my $geoname_id = $data->{'city'}{'geoname_id'};
        	#print "$address/$mask_length\t$geoname_id\n";
        } else {
        	$noCity++;
        }

        $counter++;
	    if($counter % 100000 == 0) {
	    	print "dataNode:\t$counter\tnoCity:\t$noCity\tnode:\t$nodeCounter\n";
	    }
    },
    sub{
    	$nodeCounter++
    },
);

print "start writing to file\n";
open(my $fh, '>:raw', $mmdb_file);
$tree->write_tree( $fh );
close $fh;

print "$mmdb_file has now been created\n";
print "dataNode:\t$counter\tnoCity:\t$noCity\tnode:\t$nodeCounter\n";
