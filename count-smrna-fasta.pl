#!/usr/bin/env perl
#
use strict;
use warnings;

my %counts;

while (<STDIN>){
        next if ($_ =~ /^>/ || $_ =~ /^\n/);
        chomp;
        my $len = length($_);
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