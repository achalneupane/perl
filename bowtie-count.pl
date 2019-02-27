#!/usr/bin/perl -w

# usage ./bowtie-count.pl infile outfile

$sread = "ACGT-read";
$strand ="-";
$name = "bill";
$position = 1;
$sequence = "ACGT";
$quality = "good";
$d2 = "d2";
$d3 = "d3";

open (INFILE, "<$ARGV[0]") || die "couldn't open the 1 infile!";
open (OUTFILE, ">$ARGV[1]") || die "couldn't open the 1 outfile!";
$count=0;
while ($rln = <INFILE>){
	chomp $rln;
	($sread, $strand, $name, $position, $sequence, $quality, $d2,$d3) = split("\t",$rln);
	push(@lines,$name);
	$count++;
}

print "$count\n";

@lines = sort(@lines); # sort the list
my($line);

$oldname = "bill";
$count = 0;
foreach $line (@lines) {         # loop thru list
#        print "$oldname\t$line\n";
 	if ($line eq $oldname) {
            $count++;}
        else {
            if ($count > 0) {
               print OUTFILE "$oldname\t$count\n"; # print in sort order
            }
            $oldname = $line;
            $count = 1;
        }     
	$total++; 
}

print OUTFILE "$oldname\t$count\n"; # print in sort order

print "$total\n";

close (INFILE);
close (OUTFILE);

exit;	