#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use CommonFunctions qw(parseListToArray parseFileList);

my @script_info = "
##########################################################################################
#
#	Script takes a list of .sam files and outputs:
#	File name: Total # of reads\tTotal # uniq Seqs\tTotal # reads mapped\tTotal # uniq Seqs Mapped\tTotal # reads unmapped\tTotal # uniq Seqs unmapped.
#	
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -f\tComma-separated list of files to analyse
    -o\tOutput file name\n\n";

my (%opt, $outfile, @file_list);

getopts('o:f:', \%opt);
var_check();

open (OUT, ">$outfile") or die "Cannot open $outfile\n\n";

my $file_count = 1;
my (%track, %map, %parsed, %unmap);

foreach my $file (@file_list) {
	open (IN, $file) or die " Cannot open $file: $!\n\n";
	print STDERR " Working with $file...";
	while (my $line = <IN>) {
		next if ($line =~ /^@/);
		chomp $line;
		
		my @split = split(/\t/, $line);
		my $readID = $split[0];
		
		next if ($track{$readID}{$file});
		
		my @tmp = split(/\:/, $split[0]);
		my $read_count = $tmp[1];
		
		my $hit = $split[1];
		if ($hit == 4) {
			$unmap{$file}{'reads'} += $read_count;
			$unmap{$file}{'seqs'} += 1;
		}  else {
			$map{$file}{'reads'} += $read_count;
			$map{$file}{'seqs'} += 1;
		}
		
		$parsed{$file}{'reads'} += $read_count;
		$parsed{$file}{'seqs'} += 1;
		$track{$readID}{$file} = 1;
	}
	$file_count++;
	close IN;
	print STDERR " done.\n";
}

print OUT "File\tTotalReadsParsed\tTotalSeqsParsed\tTotalReadsMapped\tTotalSeqsMapped\tTotalReadsUnmapped\tTotalSeqsUnmapped\n";
print STDERR " Printing to outfile...";
foreach my $file (@file_list) {
	print OUT "$file";
	foreach my $type (sort {$a cmp $b} keys %{$parsed{$file}}) {
		print OUT "\t$parsed{$file}{$type}";
	}
	foreach my $type (sort {$a cmp $b} keys %{$map{$file}}) {
		print OUT "\t$map{$file}{$type}";
	}
	foreach my $type (sort {$a cmp $b} keys %{$unmap{$file}}) {
		print OUT "\t$unmap{$file}{$type}";
	}
	print OUT "\n";
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
		@file_list = parseFileList($opt{'f'});
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

