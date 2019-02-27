#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use POSIX qw( ceil floor);
use Env qw(HOME);
use lib "$HOME/lib/perl";
use CommonFunctions qw(parseListToArray parseFileList);

#########################################################
# Start Variable declarations                           #
#########################################################

my @error = "
##########################################################################################
#
#	This script will generate a distribution of reads that map to the sense versus antisense of the features in -f file
#	Specific for RNAseq data --> mapped using bowtie2 (therefore strand has to be switched during analysis (dUTP-method))
#
#	Supply a comma-separated list of .bam files
#
#	Useful for feature files that have i.e. 1 feature (ChNRV1)
#
###########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -b\tdirectory with indexed BAM files
    -f\tFeatures file
    -o\tOutput filename
    ** Optional
    -C\tCatIDs to keep from -f features file for evaluation (default: 1,18-24,42,43,45,50 i.e. no strRNAs)\n\n";

my (%opt, $outfile, $feat_file, @catIDs, %catIDs, $bam_dir, @bam_files);

getopts('b:f:o:C:h', \%opt);
var_check();

foreach my $catID (@catIDs) {
	$catIDs{$catID} = 1;
	print "Category_IDs: $catID\n";
}

my $file_count = 1;
open (OUT, ">$outfile") || die "Cannot open $outfile: $!\n\n";
print OUT "Rep\tSense\tAntisense\tGroup\n";

opendir (DIR, $bam_dir) or die "Could not open Dir $bam_dir: $!\n";
my @dir_files = readdir DIR;
closedir DIR;

foreach my $bam_file (@dir_files) {
	chomp $bam_file;
	next if ($bam_file =~ /\.bai/);
	next if ($bam_file !~ /\.bam/);
	push (@bam_files, $bam_file);
}

#########################################################
# End Variable declarations                             #
#########################################################

#########################################################
# Start Main body of Program                            #
#########################################################

my $count = 1;
my (%strand_count);
my @strand = qw (sense anti);

open (FEAT, $feat_file) or die " Cannot open $feat_file: $!\n\n";
while (my $line = <FEAT>) {
	#print STDERR " Processing features... $count\r";
	next if (substr($line,0,1) eq '#');
	chomp $line;
	my ($featID, $catID, $symbol, $accession, $ref_num, $ref, $short_note, $source, $start, $end, $strand, $curator_note, $desc, $transID) = split /\t/, $line;
	next if (!exists($catIDs{$catID}));
	
	if ($strand == 1) {
		$strand = "sense";
	} else {
		$strand = "anti";
	}
	my $flength = $end - $start + 1;

	foreach my $bam_file (@bam_files) {
		chomp $bam_file;
		next if ($bam_file =~ /\.bai/);
		next if ($bam_file !~ /\.bam/);
		
		print STDERR " Working with $bam_file...";
		
		open (BAM, "samtools view $bam_dir/$bam_file '$ref:$start-$end' |");
		while (my $sam = <BAM>) {
			chomp $sam;
			my @split_sam = split(/\t/, $sam);
			my $sid = $split_sam[0];
			
			my $read_strand = $split_sam[1];
			my $strand_combo;
			
			#Specific to dUTP strand-specific RNA-seq
			if ($read_strand == 16 && $strand eq "sense") {
				$strand_combo = "sense";
			} elsif ($read_strand == 0 && $strand eq "anti") {
				$strand_combo = "sense";
			} elsif ($read_strand == 0 && $strand eq "sense") {
				$strand_combo = "anti";
			} elsif ($read_strand == 16 && $strand eq "anti") {
				$strand_combo = "anti";
			} else {
				print "$sid\tOther condition\n";
			}
			
			$strand_count{$strand_combo}{$bam_file} += 1;
		}
		close BAM;
		print STDERR " done.\n";
	}
	$count++;
}
close FEAT;
print STDERR "done.\n";

print STDERR " Printing to outfile...";
foreach my $file (@bam_files) {
	my $row_name = $file;
	$row_name =~ s/_RNAseq\.bowtie2\.finalGenome\.bam//;
	
	my @rep = split(/\_/, $row_name);
	my $rep = "Rep" . $rep[1];
	my $group = $rep[0];
	
	print OUT "$rep";
	foreach my $hit_strand (@strand) {
		print OUT "\t$strand_count{$hit_strand}{$file}";
	}
	print OUT "\t$group\n";
}
close OUT;

print STDERR "done.\n";
close OUT;
exit;

#########################################################
# Start Subroutines                                     #
#########################################################

#########################################################
# Start of Varriable Check Subroutine "var_check"       #
#########################################################

sub var_check {
	if ($opt{'h'}) {
		var_error();
	}
	if ($opt{'C'}) {
		@catIDs = parseListToArray($opt{'C'});
	} else {
		@catIDs = parseListToArray('1,18-24,42,43,45,50');
	}
	if ($opt{'o'}) {
		$outfile = $opt{'o'};
	} else {
		var_error();
	}
	if ($opt{'b'}) {
		$bam_dir = $opt{'b'};
	} else {
		var_error();
	}
	if ($opt{'f'}) {
		$feat_file = $opt{'f'};
	} else {
		var_error();
	}
}

#########################################################
# End of Varriable Check Subroutine "var_check"         #
#########################################################

#########################################################
# Start of Varriable error Subroutine "var_error"       #
#########################################################

sub var_error {
	print "@error";
	exit 0;
}

#########################################################
# End of Varriable error Subroutine "var_error"         #
#########################################################
