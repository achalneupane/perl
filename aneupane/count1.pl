#!/usr/bin/perl
use warnings;
use strict;

my $infile = $ARGV[0];
my $min = $ARGV[1];
my $max = $ARGV[2];
my %hash = ();
$/ = ">";

open (INFILE, "<$infile") || die "couldn't open input file!";
while (<INFILE>) {
    chomp;
    next if ( /^\s*$/ );
    my ($header, $seq) = split("\n");
    my $seq_len = length($seq);
    next if ($seq_len < $min || $seq_len > $max);
    $hash{$seq_len}[1] += 1;
    $hash{$seq_len}[2] += () = $seq =~ /A/gi;
    $hash{$seq_len}[3] += () = $seq =~ /C/gi;
    $hash{$seq_len}[4] += () = $seq =~ /G/gi;
    $hash{$seq_len}[5] += () = $seq =~ /T/gi;
}
close(INFILE);
#print "length\tnumber\tA\tC\tG\tT\n";
#for my $len ( sort keys %hash ) {
#    print "$len\t";
#    for my $i ( 1 .. 5 ) {
#        print "$hash{$len}[$i]\t";
#    }
#    print "\n";
#}

##Print like this:
print "length\tnumber\tA\tC\tG\tT\n";
foreach my $len ( $min .. $max ) {
    print "$len\t";
    if ( exists( $hash{$len} ) ) {
        foreach my $i ( 1 .. 5 ) {
            print "$hash{$len}[$i]\t";
        }
        print "\n";
    }
    else { print "0\t0\t0\t0\t0\n"; }
}
