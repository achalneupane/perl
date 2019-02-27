#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use vars qw/ $opt_b $opt_o /;

my @script_info = "
##########################################################################################
#	Script opens .bam file (ie unmapped.bam from TOPHAT) and re-formats the reads that don't
#	map to fastq format
#	Output format: 
#	\@HW-ST997:516:C3J5WACXX:2:2308:17553:54616
#	TTTTACTAAAAATATAGTTCAGGGCTTTAGGCACCATCAATT
#	+
#	#1=DDFFFHHHHHJJJJIJJJJJJJJJJIIIJJIIJJJJGEHJJJHIHII
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -b\t.bam file
    -o\toutput file\n\n";

getopts('b:o:');
&var_check();

my ($bam, $outfile);

open (BAM, $bam) || die "Cannot open $bam: $!\n\n";
open (OUT, ">$outfile") || die "Cannot open outfile: $outfile: $!\n\n";

open BAM, "samtools view $bam |";
while (my $line = <BAM>) {
	chomp $line;
	
	my @split = split(/\t/, $line);
	my $hit = $split[1];
	next if ($hit != 4);
	my $name = $split[0];
	my $seq = $split[9];
	my $qual = $split[10];
	
	print OUT "@" . "$name\n";
	print OUT "$seq\n";
	print OUT "+\n";
	print OUT "$qual\n";
}
close BAM;
close OUT;
exit;

sub var_check {
    if ($opt_b) {
            $bam = $opt_b;
    } else {
            &var_error();
    }
    if ($opt_o) {
            $outfile = $opt_o;
    } else {
            &var_error();
    }
}

sub var_error {
	print "@script_info";
	exit 0;
}




exit;
