#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
#use Statistics::Descriptive;
use CommonFunctions qw(parseListToArray parseFileList);

my @script_info = "
##########################################################################################
#
#	Script takes two lists of .txt output files from get_RNAseq_mapped_unmapped_stats.pl or
#	get_parsed_mapped_unmapped_stats.pl
#	-o: stats for original genome alignments
#	-f: stats for final genome alignments
#	-r: Rformat output file [average percent / category of ori_map, new_map, still_unmap]
#
#	Output format is:
#	Group\tData\tSource
#	ago1	   44.5	oriMap
#	
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -o\tComma-separated list of map/unmap files for original genome alignments
    -f\tComma-separated list of map/unmap files for final genome alignments
    -r\tOutput file [will be Rformat]\n\n";

my (%opt, $outfile, @oriFiles, @finalFiles);

getopts('o:f:r:', \%opt);
var_check();

open (OUT, ">$outfile") or die "Cannot open $outfile\n\n";

my (@group, %ori, %final, %group_count);

foreach my $file (@oriFiles) {
	open (IN, $file) or die " Cannot open $file: $!\n\n";
	my @name = split(/\_/, $file);
	my $group = $name[0];
	if ($group =~ /controls4/) {
		$group = "controls";
	}
	
	push(@group, $group);
	
	print STDERR " Working with $file...";
	while (my $line = <IN>) {
		next if ($line =~ /^File/);
		chomp $line;
		
		my @split = split(/\t/, $line);
		
		my $totalReads = $split[1];
		my $mappedReads = $split[3];
		
		my $percent_map = $mappedReads / $totalReads * 100;
		
		$ori{$group}{'map'} += $percent_map;
		$group_count{$group} += 1;
	}
	close IN;
	print STDERR " done.\n";
}

foreach my $file (@finalFiles) {
	open (FINAL, $file) or die " Cannot open $file: $!\n\n";
	my @name = split(/\_/, $file);
	my $group = $name[0];
	
	print STDERR " Working with $file...";
	while (my $line = <FINAL>) {
		next if ($line =~ /^File/);
		chomp $line;
		
		my @split = split(/\t/, $line);
		
		my $totalReads = $split[1];
		my $mappedReads = $split[3];
		my $unmapReads = $split[5];
		
		my $percent_map = $mappedReads / $totalReads * 100;
		my $percent_unmap = $unmapReads / $totalReads * 100;
		
		$final{$group}{'map'} += $percent_map;
		$final{$group}{'unmap'} += $percent_unmap;
	}
	close FINAL;
	print STDERR " done.\n";
}

print OUT "Group\tData\tSource\n";
my @mappings = qw (map unmap);

foreach my $group (@group) {
	my $group_count = $group_count{$group};
	
	foreach my $map (keys %{$ori{$group}}) {
		my $oriMap = sprintf("%.1f", $ori{$group}{$map} / $group_count);
		print OUT "$group\t$oriMap\toriMap\n";
		
		my $finalMap = sprintf("%.1f", ($final{$group}{$map} / $group_count) - $oriMap);
		print OUT "$group\t$finalMap\tfinalMap\n";
		
		my $stillUnmap = sprintf("%.1f", ($final{$group}{'unmap'} / $group_count));
		print OUT "$group\t$stillUnmap\tstillUnmap\n";
	}
}
print STDERR " done.\n";
close OUT;
exit;

#########################################################
# Start of Varriable Check Subroutine "var_check"       #
#########################################################

sub var_check {
	if ($opt{'r'}) {
		$outfile = $opt{'r'};
	} else {
		var_error();
	}
	if ($opt{'o'}) {
		@oriFiles = parseFileList($opt{'o'});
	} else {
		var_error();
	}
	if ($opt{'f'}) {
		@finalFiles = parseFileList($opt{'f'});
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

