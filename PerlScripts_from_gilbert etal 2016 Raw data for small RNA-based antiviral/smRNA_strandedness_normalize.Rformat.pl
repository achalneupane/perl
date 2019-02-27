#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use CommonFunctions qw(parseListToArray parseFileList);

my @script_info = "
##########################################################################################
#
#	Script takes
#	1. output file from readsPerFeature.strand.byRep.smRNA.pl which contain read data by strand, mapped to ChNRV1
#	2. totalReads_table_smRNA.txt for the total parsed reads data for normalization.
#	
#	Output format is:
#	Rep\tSenseReads\tAntiReads\tTotalChNRV1\tSense_Antisense_Ratio\tGroup(Genotype)
#	
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -i\toutput file from readsPerFeature.strand.byRep.smRNA.pl
    -n\tFile containing totalParsedReads
    -o\tOutput file name\n\n";

my (%opt, $outfile, $infile, $norm_file);

getopts('i:o:n:', \%opt);
var_check();

open (OUT, ">$outfile") or die "Cannot open $outfile\n\n";
print OUT "Rep\tSenseReads\tAntiReads\tTotalChNRV1\tSense_Antisense_Ratio\tGroup\n";

open (NORM, $norm_file) || die "Cannot open $norm_file: $!\n\n";
my (%norm, %id);

my $counter = 1;
while (my $line = <NORM>) {
	chomp $line;
	next if ($line =~ /Group/);
	
	my ($group, $rep, $totalReads, $libID) = split(/\t/, $line);
	if ($group =~ /plasmid/ || $group =~ /WT/) {
		$group = "Controls";
		$rep = $counter;
		$counter++;
	}
	$norm{$libID} = $totalReads;
	$id{$libID} = "$group\t$rep";
}
close NORM;

open (IN, $infile) or die " Cannot open $infile: $!\n\n";

while (my $line = <IN>) {
	next if ($line =~ /^LibraryID/);
	chomp $line;
	
	my @split = split(/\t/, $line);
	my $libID = $split[0];
	my $senseReads = $split[3];
	$senseReads = sprintf("%.2f",$senseReads * 1000000 / $norm{$libID});
	my $antiReads = $split[4];
	$antiReads = sprintf("%.2f",$antiReads * 1000000 / $norm{$libID});
	my $totalReads = $split[5];
	$totalReads = sprintf("%.2f",$totalReads * 1000000 / $norm{$libID});
	
	my $strand_ratio = sprintf("%.2f",$senseReads / $antiReads);
	
	my ($group, $rep) = split(/\t/, $id{$libID});
	
	print OUT "$rep\t$senseReads\t$antiReads\t$totalReads\t$strand_ratio\t$group\n";
}
close IN;
close OUT;
exit;

#########################################################
# Start of Varriable Check Subroutine "var_check"       #
#########################################################

sub var_check {
	if ($opt{'o'}) {
		$outfile = $opt{'o'};
	} else {
		var_error();
	}
	if ($opt{'i'}) {
		$infile = $opt{'i'};
	} else {
		var_error();
	}
	if ($opt{'n'}) {
		$norm_file = $opt{'n'};
	} else {
		var_error();
	}
}

#########################################################
# Start of Varriable error Subroutine "var_error"       #
#########################################################

sub var_error {
	print "@script_info";
	exit 1;
}

