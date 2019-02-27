#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use CommonFunctions qw(parseListToArray parseFileList);

my @script_info = "
##########################################################################################
#
#	Script takes the output files from hitsPerNT.smRNA.strand.pl which contain the strand
#	information for RPM for ChNRV1 for AGO1 input & AGO1 IP and combines and re-formats the
#	data for plotting in R.
#	
#	Output format is:
#	Position\tforward_ratio\treverse_ratio\tGroup(Genotype)
#	
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -f\tComma-separated list of output files from hitsPerNT.smRNA.strand.pl
    -o\tOutput file name\n\n";

my (%opt, $outfile, @files);

getopts('o:f:', \%opt);
var_check();

open (OUT, ">$outfile") or die "Cannot open $outfile\n\n";
print OUT "Position\tforward\treverse\tGroup\n";

my (@group);

foreach my $file (@files) {
	open (IN, $file) or die " Cannot open $file: $!\n\n";
	my @name = split(/\_/, $file);
	my $group = $name[0];
	if ($file =~ /input/ || $file =~ /IP/) {
		$group .= $name[1];
	}
	
	push(@group, $group);
	
	print STDERR " Working with $file...";
	while (my $line = <IN>) {
		next if ($line =~ /^Pos/);
		chomp $line;
		
		my @split = split(/\t/, $line);
		my $pos = $split[0];
		my $for = $split[1];
		my $rev = $split[2];
		
		print OUT "$pos\t$for\t$rev\t$group\n";
	}
	close IN;
	print STDERR " done.\n";
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

