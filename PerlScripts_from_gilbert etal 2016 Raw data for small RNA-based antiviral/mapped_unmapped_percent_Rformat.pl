#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use Statistics::Descriptive;
use CommonFunctions qw(parseListToArray parseFileList);

my @script_info = "
##########################################################################################
#
#	Script takes a list of .txt output files from get_RNAseq_mapped_unmapped_stats.pl
#	and determines the percent of reads mapped & unmapped.
#	
#	Output format is:
#	Rep\tPercentMapped\tPercentUnmapped\tGroup(Genotype)
#	
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -f\tComma-separated list of FORWARD strand files to analyse
    -o\tOutput file name\n\n";

my (%opt, $outfile, @files);

getopts('o:f:', \%opt);
var_check();

open (OUT, ">$outfile") or die "Cannot open $outfile\n\n";

my (@group, %hash);
my @mappings = qw (map unmap);

foreach my $file (@files) {
	open (IN, $file) or die " Cannot open $file: $!\n\n";
	my @name = split(/\_/, $file);
	my $group = $name[0];
	push(@group, $group);
	my $count = 1;
	
	print STDERR " Working with $file...";
	while (my $line = <IN>) {
		next if ($line =~ /^File/);
		chomp $line;
		
		my @split = split(/\t/, $line);
		my $rep = $group . "_" . $count;
		my $totalReads = $split[1];
		my $mappedReads = $split[3];
		my $unmapReads = $split[5];
		
		my $percent_map = $mappedReads / $totalReads * 100;
		my $percent_unmap = $unmapReads / $totalReads * 100;
		
		$hash{$rep}{'map'} = $percent_map;
		$hash{$rep}{'unmap'} = $percent_unmap;
		$count++;
	}
	close IN;
	print STDERR " done.\n";
}

print OUT "Group\tMeanPercentMap\tStDevMap\tMeanPercentUnmap\tStDevUnmap\tCount\n";
print STDERR " Printing to outfile...";

foreach my $group (@group) {
	my $map_stat=Statistics::Descriptive::Full->new();
	my $unmap_stat=Statistics::Descriptive::Full->new();
	
	for (my $i = 1; $i <= 4; $i++) {
		my $rep = $group . "_" . $i;
		next if (!exists($hash{$rep}{'map'}));
		
		my $percent = $hash{$rep}{'map'};
		$map_stat->add_data($percent);
		
		$percent = $hash{$rep}{'unmap'};
		$unmap_stat->add_data($percent);
	}
	
	my $map_mean = sprintf("%.1f", $map_stat->mean());
	my $unmap_mean = sprintf("%.1f", $unmap_stat->mean());
	
	my $map_sd = sprintf("%.1f", $map_stat->standard_deviation());
	my $unmap_sd = sprintf("%.1f", $unmap_stat->standard_deviation());
	
	my $map_N = $map_stat->count();
	my $unmap_N = $unmap_stat->count();
	if ($map_N != $unmap_N) {
		print STDERR "\nDifferent number of data points in Map vs Unmap\nScript quitting\n";
		exit;
	}
	
	print OUT "$group\t$map_mean\t$map_sd\t$unmap_mean\t$unmap_sd\t$map_N\n";
	
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
	if ($opt{'f'}) {
		@files = parseFileList($opt{'f'});
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

