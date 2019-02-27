#!/usr/bin/perl
use strict;
use warnings;

open (DATA, "/home/owner/SLM/Desktop/Documents/retrotransposons/Dcld_1_LTR_assembly_file.txt") or die ("Unable to open file");
my $search_string = "reads";

my $header = <DATA>;
my @header_titles = split /\t/, $header;
my $extract_col = 0;

for my $header_line (@header_titles) {
  last if $header_line =~ m/$search_string/;
  $extract_col++;
}

print "Extracting column $extract_col\n";

while ( my $row = <DATA> ) {
  last unless $row =~ /\S/;
  chomp $row;
  my @cells = split /\t/, $row;
  print "$cells[$extract_col] ";
}
