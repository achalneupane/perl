use warnings;
use strict;
use feature 'say';

my $file = shift;
die "Usage $0 file\n" if not $file;

open my $fh, '<', $file  or die "Can't open $file: $!";

my (@res, @query, $category, $pvalue);

while (<$fh>) {
    next if not /\S/;

    if (/(.*?)\s*Query:\s+(.*)/) {
        @query = ($1, $2);
        next;
    }   

    if (/^\s*(Degardome Category:\s+([0-9]+))/) {
        $category = $1; 
    }   
    elsif (/^\s*(Degradome p-value: [0-9.]+)/) {
        $pvalue = $1; 
        push @res, [$category, $pvalue, @query];
    }   
}

say "@$_" for @res;
