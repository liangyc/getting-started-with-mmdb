#!/usr/bin/env perl

use strict;
use warnings;
use feature qw( say );

use Data::Printer;
use MaxMind::DB::Reader;
use Net::Works::Address;

my $csv_file = $ARGV[0];
my $reader = MaxMind::DB::Reader->new( file => $csv_file );
 
my $i = 0;

$reader->iterate_search_tree(
    sub {
        my $ip_as_integer = shift;
        my $mask_length   = shift;
        my $data          = shift;

        my $address = Net::Works::Address->new_from_integer(
            integer => $ip_as_integer );
        #say join '/', $address->as_ipv4_string, $mask_length;
        #say np $data;
        $i++
   }
);

print "start writing to file\n";

