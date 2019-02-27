#!/usr/bin/perl
use warnings;
use strict;

my $infile = $ARGV[0];
my $min = $ARGV[1];
my $max = $ARGV[2];
my( %lenhash, %Ahash, %Chash, %Ghash, %Thash );
$/ = ">";

open (INFILE, "<$infile") or die "couldn't open input file!";
while (<INFILE>) {
    my %count;
    chomp;
    next if ( /^\s*$/ );
    my ($header, $seq) = split("\n");
    my $seq_len = length($seq);
    next if ($seq_len < $min || $seq_len > $max);
    foreach my $base (split "", $seq) {
        $count{$base}++;
    }
    $lenhash{$seq_len} += 1;
    $Ahash{$seq_len} += $count{"A"};
    $Chash{$seq_len} += $count{"C"};
    $Ghash{$seq_len} += $count{"G"};
    $Thash{$seq_len} += $count{"T"};
}
close(INFILE);
print "length\tnumber\tA\tC\tG\tT\n";
for my $len ( sort keys %lenhash ) {
    print "$len\t$lenhash{$len}\t$Ahash{$len}\t$Chash{$len}\t$Ghash{$len}\t$Thash{$len}\n";
}
