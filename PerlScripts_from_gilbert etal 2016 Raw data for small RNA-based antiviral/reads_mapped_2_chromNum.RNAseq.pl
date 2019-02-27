#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use POSIX qw( ceil floor);
use CommonFunctions qw(parseListToArray parseFileList);

my @script_info = "
##########################################################################################
#
#	Script takes a list of chrom names (ie mtRNA_contig, rRNA_contig, ChNRV1)
#	and outputs:
#	chromName	RawReadCounts (uniq to those chrom's)
#
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -b\tPath to INDEXED .bam file(s) [Can provide all reps to be summarized]
    -c\tList of chromNames
    -o\tOutput file name
    -n\tName for countsColumn (ie ago1_RNAseq)\n\n";

my (%opt, $outfile, @bam_list, @chromNames, $header);

getopts('b:o:c:n:', \%opt);
var_check();

open (OUT, ">$outfile") || die "Cannot open $outfile: $!\n\n";
print OUT "ChromNum\t$header\n";

my %chromNames;
print " Features to find:\n";
foreach my $type (@chromNames) {
	$chromNames{$type} = 1;
	print "\t$type\n";
}

my %sids;

print STDERR " Getting SIDs that map to the features above...\n";
my $line_count = 0;
my $file_count = 1;

foreach my $bam_file (@bam_list) {
	print STDERR " Working with $bam_file...\n";
	foreach my $chrom (@chromNames) {
		$line_count = 0;
		open (BAM, "samtools view $bam_file $chrom |");
		while (my $sam = <BAM>) {
			chomp $sam;
			my @get_sid = split(/\t/, $sam);
			my $sid = $get_sid[0];
			$sids{$sid}{$chrom} += 1;
			
			$line_count++;
		}
		close BAM;
		
		if ($line_count == 0) {
			print STDERR "No SIDs found for $chrom. May want to check it is a valid chromAccession\n";
			$chromNames{$chrom} = 1;
		}
		print STDERR "     Line count $chrom: $line_count\n";
	}
	print STDERR " Working with $bam_file...done.\n";
	
	print STDERR " Removing SIDs that map to other chromNums...";
	my %seq;
	
	open (SAM, "samtools view $bam_file |");
	my $delete_count = 0;
	while (my $sam = <SAM>) {
		chomp $sam;
		my @get_sid = split(/\t/, $sam);
		my $sid = $get_sid[0];
		my $chromName = $get_sid[2];
		next if (exists($chromNames{$chromName}));
		
		if (exists($sids{$sid})) {
			delete($sids{$sid});
			$delete_count++;
			next;
		}
	}
	close SAM;
	print STDERR " done.\n";
	print STDERR " Removed $delete_count SIDs due to multiple mappings\n";
}

#foreach my $chrom (@chromNames) {
#	$line_count = 0;
#	open (BAM, "samtools view $bam $chrom |");
#	
#	while (my $sam = <BAM>) {
#		chomp $sam;
#		my @get_sid = split(/\t/, $sam);
#		my $sid = $get_sid[0];
#		$sids{$sid}{$chrom} = 1;
#		
#		$line_count++;
#	}
#	close BAM;
#	
#	if ($line_count == 0) {
#		print STDERR "No SIDs found for $chrom. May want to check it is a valid chromAccession\n";
#		$chromNames{$chrom} = 1;
#	}
#	print STDERR " Line count $chrom: $line_count\n";
#}

#	Go through and delete sids from hash that map to other chromNums
#print STDERR " Removing SIDs that map to other chromNums...";
#my %seq;
#
#open (SAM, "samtools view $bam |");
#my $delete_count = 0;
#while (my $sam = <SAM>) {
#	chomp $sam;
#	my @get_sid = split(/\t/, $sam);
#	my $sid = $get_sid[0];
#	my $chromName = $get_sid[2];
#	next if (exists($chromNames{$chromName}));
#	
#	if (exists($sids{$sid})) {
#		delete($sids{$sid});
#		$delete_count++;
#		next;
#	}
#}
#close SAM;
#print STDERR " done.\n";
#print STDERR " Removed $delete_count SIDs due to multiple mappings\n";

my %out_hash;

foreach my $sid (keys %sids) {
	foreach my $chromName (keys %{$sids{$sid}}) {
		$out_hash{$chromName} += 1;
	}
}
	
foreach my $chromName (@chromNames) {
	print OUT "$chromName\t$out_hash{$chromName}\n";
}

close OUT;
print STDERR " done.\n";
exit 0;


#########################################################
# Start of Varriable Check Subroutine "var_check"       #
#########################################################

sub var_check {
	if ($opt{'b'}) {
		@bam_list = parseFileList($opt{'b'});
	} else {
		var_error();
	}
	if ($opt{'n'}) {
		$header = $opt{'n'};
	} else {
		var_error();
	}
	if ($opt{'o'}) {
		$outfile = $opt{'o'};
	} else {
		var_error();
	}
	if ($opt{'c'}) {
		@chromNames = parseListToArray($opt{'c'});
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
