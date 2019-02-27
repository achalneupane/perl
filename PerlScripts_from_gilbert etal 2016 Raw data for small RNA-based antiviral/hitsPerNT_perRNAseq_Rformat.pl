#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use CommonFunctions qw(parseListToArray parseFileList);

my @script_info = "
##########################################################################################
#
#	Script takes
#	1. a list of .txt output files from hitsPerNT.smRNA.strand.pl which contain the strand information for RPM for ChNRV1
#	2. output from readsPerFeature.strand.byRep.RNAseq.pl (RPM by strand of RNAseq for each replicate); data from
#	this file is averaged and used to 'normalize' the smRNA data to be a function of RNAseq amounts.
#	
#	Output format is:
#	Position\tforward_ratio\treverse_ratio\tGroup(Genotype)
#	
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -f\tComma-separated list of smRNA outputs from hitsPerNT.smRNA.strand.pl
    -r\tRNAseq data, by strand (from readsPerFeature.strand.byRep.RNAseq.pl)
    -n\tFile containing totalParsedReads for RNAseq (to normalize the counts in -r file)
    -o\tOutput file name\n\n";

my (%opt, $outfile, @files, $rnaseq_file, $norm_file);

getopts('o:f:r:n:', \%opt);
var_check();

open (OUT, ">$outfile") or die "Cannot open $outfile\n\n";
print OUT "Position\tforward_ratio\treverse_ratio\tGroup\n";

open (NORM, $norm_file) || die "Cannot open $norm_file: $!\n\n";
my %norm;

while (my $line = <NORM>) {
	chomp $line;
	next if ($line =~ /Group/);
	
	my ($group, $rep, $totalReads) = split(/\t/, $line);
	if ($group =~ /plasmid/ || $group =~ /WT/) {
		$group = "Controls";
	}
	
	$norm{$group}{$rep} = $totalReads;
}
close NORM;

open (RNA, $rnaseq_file) || die "Cannot open $rnaseq_file: $!\n\n";

my (%rna_hash, %rna_avg, @group);

while (my $line = <RNA>) {
	chomp $line;
	next if ($line =~ /Sense/);
	
	my @split = split(/\t/, $line);
	my $sense = $split[1];
	my $anti = $split[2];
	my $group = $split[3];

	if ($group =~ /plasmid/ || $group =~ /WT/) {
		$group = "Controls";
	}
	
	my $rep = $split[0];
	$rep =~ s/Rep//;
	my $totalReads = $norm{$group}{$rep};
	
	$rna_hash{$group}{'sense'} += $sense * 1000000 / $totalReads;
	$rna_hash{$group}{'anti'} += $anti * 1000000 / $totalReads;
	$rna_hash{$group}{'count'} += 1;
}
close RNA;

foreach my $group (keys %rna_hash) {
	my $count = $rna_hash{$group}{'count'};
	my $sense_avg = $rna_hash{$group}{'sense'} / $count;
	my $anti_avg = $rna_hash{$group}{'anti'} / $count;
	
	$rna_avg{$group}{'sense'} = $sense_avg;
	$rna_avg{$group}{'anti'} = $anti_avg;
}

foreach my $file (@files) {
	open (IN, $file) or die " Cannot open $file: $!\n\n";
	my @name = split(/\_/, $file);
	my $group = $name[0];
	if ($group =~ /controls/) {
		$group = "Controls";
	}
	
	push(@group, $group);
	
	if (!exists($rna_avg{$group})) {
		print STDERR "\n$group does not have RNAseq data. Script is exiting\n";
		exit;
	}
	
	print STDERR " Working with $file...";
	while (my $line = <IN>) {
		next if ($line =~ /^Pos/);
		chomp $line;
		
		my @split = split(/\t/, $line);
		my $pos = $split[0];
		my $for = $split[1];
		my $rev = $split[2];
		
		my $rnaseq_for = $rna_avg{$group}{'sense'};
		my $rnaseq_rev = $rna_avg{$group}{'anti'};
		
		$for = sprintf("%.2e", $for/$rnaseq_for);
		$rev = sprintf("%.2e", $rev/$rnaseq_rev);
		
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
	if ($opt{'r'}) {
		$rnaseq_file = $opt{'r'};
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

