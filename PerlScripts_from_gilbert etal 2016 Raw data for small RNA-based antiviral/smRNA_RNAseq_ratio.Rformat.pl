#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use CommonFunctions qw(parseListToArray parseFileList);

my @script_info = "
##########################################################################################
#
#	Script takes
#	1. smRNA normalized data (output file from smRNA_strandedness_normalize.Rformat.pl)
#	2. RNAseq normalized data (output file from readsPerFeature.strand.byRep.RNAseq.norm.pl)
#	
#	Output format is:
#	Rep\tsmRNA_RNAseq_Ratio\tGroup(Genotype)
#	
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -s\tsmRNA input file
    -r\tRNAseq input file
    -o\tOutput file name\n\n";

my (%opt, $outfile, $smRNA_file, $RNAseq_file);

getopts('s:r:o:', \%opt);
var_check();

open (OUT, ">$outfile") or die "Cannot open $outfile\n\n";
print OUT "Rep\tsmRNA_RNAseq_Ratio\tGroup\n";

open (RNA, $RNAseq_file) || die "Cannot open $RNAseq_file: $!\n\n";
my (%rna_hash);

while (my $line = <RNA>) {
	chomp $line;
	next if ($line =~ /Group/);
	
	my @split = split(/\t/, $line);
	my $rep_total = $split[3];
	my $group = $split[4];
	
	$rna_hash{$group}{'reads'} += $rep_total;
	$rna_hash{$group}{'reps'} += 1;
}
close RNA;

open (SM, $smRNA_file) or die " Cannot open $smRNA_file: $!\n\n";

while (my $line = <SM>) {
	next if ($line =~ /Group/);
	chomp $line;
	
	my @split = split(/\t/, $line);
	my $smRNA_reads = $split[3];
	my $group = $split[5];
	my $rep = $split[0];
	
	my $rna_total = $rna_hash{$group}{'reads'};
	my $rna_reps = $rna_hash{$group}{'reps'};
	my $rna_avg = $rna_total / $rna_reps;
	
	my $smRNA_RNA_ratio = sprintf("%.2f",$smRNA_reads / $rna_avg);
	
	print OUT "$rep\t$smRNA_RNA_ratio\t$group\n";
}
close SM;
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
	if ($opt{'s'}) {
		$smRNA_file = $opt{'s'};
	} else {
		var_error();
	}
	if ($opt{'r'}) {
		$RNAseq_file = $opt{'r'};
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

