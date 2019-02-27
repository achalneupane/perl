use strict;
use warnings;

while (my $line = <>) {
    next unless $line =~ /length/;
    next unless $line = <>;
    my @fields = $line;
    print "@fields[0]\n";
}