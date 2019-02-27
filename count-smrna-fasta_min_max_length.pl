#!/usr/bin/env perl
#
use strict;
use warnings;

#usage: perl count-smrna-fasta_test.pl test.fasta min_seq_length max_seq_length

my %counts;


## Usage : perl file.pl infile min_len max_len

my $infile = $ARGV[0];
my $min = $ARGV[1];
my $max = $ARGV[2];



open (INFILE, "<$infile") || die "couldn't open input file!";
while (<INFILE>) {
        chomp;
        next if ( /^\s*$/ );
        my $len = length($_);
        next if ($len < $min || $len > $max);
        my $fb = substr($_,0,1);
        $counts{$len}{'count'}++;
        if (!$counts{$len}{'A'}) {$counts{$len}{'A'} =0;}
        if (!$counts{$len}{'C'}) {$counts{$len}{'C'} =0;}
        if (!$counts{$len}{'G'}) {$counts{$len}{'G'} =0;}
        if (!$counts{$len}{'T'}) {$counts{$len}{'T'} =0;}
        $counts{$len}{$fb}++;

}

print "length\tnumber\tA\tT\tG\tC\n";
foreach my $c (sort keys %counts){
        print "$c\t$counts{$c}{'count'}\t$counts{$c}{'A'}\t$counts{$c}{'T'}\t$counts{$c}{'G'}\t$counts{$c}{'C'}\n";
}

exit;