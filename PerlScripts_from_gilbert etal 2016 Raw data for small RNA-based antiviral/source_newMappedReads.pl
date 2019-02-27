#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
#use Statistics::Descriptive;
use CommonFunctions qw(parseListToArray parseFileList);

my @script_info = "
##########################################################################################
#
#	Script takes a lists of .txt output files from reads_mapped_2_chromNum.RNAseq.pl and
#	creates a combined summary file in Rformat.
#
#	Output format is:
#	Group\tData(Percent)\tSource
#	ago1	   81.8	ChNRV1
#	
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -i\tComma-separated list of source of novel mappings
    -o\tOutput file [will be Rformat]\n\n";

my (%opt, $outfile, @novelFiles);

getopts('o:i:', \%opt);
var_check();

open (OUT, ">$outfile") or die "Cannot open $outfile\n\n";

my (@group, %novel, %total);

foreach my $file (@novelFiles) {
	open (IN, $file) or die " Cannot open $file: $!\n\n";
	my @name = split(/\_/, $file);
	my $group = $name[0];
	if ($group =~ /controls4/) {
		$group = "controls";
	}
	push(@group, $group);
	
	print STDERR " Working with $file...";
	my $totalReads = 0;
	while (my $line = <IN>) {
		next if ($line =~ /^ChromNum/);
		chomp $line;
		
		my @split = split(/\t/, $line);
		
		my $source = $split[0];
		$totalReads += $split[1];
		my $reads = $split[1];
		
		$novel{$group}{$source} += $reads;
	}
	$total{$group} = $totalReads;
	close IN;
	print STDERR " done.\n";
}

print OUT "Group\tData\tSource\n";

foreach my $group (@group) {
	my $total = $total{$group};
	
	foreach my $source (keys %{$novel{$group}}) {
		my $mapped = sprintf("%.1f", $novel{$group}{$source} / $total * 100);
		print OUT "$group\t$mapped\t$source\n";
	}
}
print STDERR " done.\n";
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
		@novelFiles = parseFileList($opt{'i'});
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

