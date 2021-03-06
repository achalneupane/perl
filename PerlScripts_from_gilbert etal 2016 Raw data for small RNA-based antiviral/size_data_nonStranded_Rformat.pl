#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use CommonFunctions qw(parseListToArray parseFileList);

my @script_info = "
##########################################################################################
#
#	Script takes a list of .txt output files from sizeNT_byCatID.byRep.byStrand.FinalGenome.pl
#	and extracts just the size information but does not break it up by strand. 
#	
#	Output format is:
#	Size\tData(Percent)\tGroup(Genotype)
#	
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -f\tComma-separated list of FORWARD strand files to analyse
    -r\tComma-separated list of REVERSE strand files to analyse
    -o\tOutput file name\n\n";

my (%opt, $outfile, @forward_list, @reverse_list);

getopts('o:f:r:', \%opt);
var_check();

open (OUT, ">$outfile") or die "Cannot open $outfile\n\n";

my (%size, %total, @group);
my @sizes = qw (18 19 20 21 22 23 24 25 26 27);

foreach my $forward_file (@forward_list) {
	open (IN, $forward_file) or die " Cannot open $forward_file: $!\n\n";
	my @name = split(/\_/, $forward_file);
	my $group = $name[0];
	if ($group =~ /controls/) {
		$group = "Controls";
	}
	if ($forward_file =~ /input/ || $forward_file =~ /IP/) {
		$group = $name[0] . $name[1]; 
	}
	
	push(@group, $group);
	
	print STDERR " Working with $forward_file...";
	while (my $line = <IN>) {
		next if ($line =~ /^Length/);
		last if ($line =~ /^NT/);
		chomp $line;
		
		my @split = split(/\t/, $line);
		my $size = $split[0];
		my $total = pop(@split);
		
		$size{$group}{$size} += $total;
		$total{$group} += $total;
	}
	close IN;
	print STDERR " done.\n";
}

foreach my $reverse_file (@reverse_list) {
	open (IN, $reverse_file) or die " Cannot open $reverse_file: $!\n\n";
	my @name = split(/\_/, $reverse_file);
	my $group = $name[0];
	if ($group =~ /controls/) {
		$group = "Controls";
	}
	if ($reverse_file =~ /input/ || $reverse_file =~ /IP/) {
		$group = $name[0] . $name[1]; 
	}
	
	print STDERR " Working with $reverse_file...";
	while (my $line = <IN>) {
		next if ($line =~ /^Length/);
		last if ($line =~ /^NT/);
		chomp $line;
		
		my @split = split(/\t/, $line);
		my $size = $split[0];
		my $total = pop(@split);
		
		$size{$group}{$size} += $total;
		$total{$group} += $total;
	}
	close IN;
	print STDERR " done.\n";
}

print OUT "Size\tData\tGroup\n";
print STDERR " Printing to outfile...";

foreach my $group (@group) {
	foreach my $size (@sizes) {
		print OUT "$size";
		if (exists($size{$group}{$size})) {
			my $total = $total{$group};
			my $count = $size{$group}{$size};
			my $percent = sprintf("%.1f", $count / $total * 100);
			
			print OUT "\t$percent";
		} else {
			print OUT "\t0";
		}
		print OUT "\t$group\n";
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
	if ($opt{'f'}) {
		@forward_list = parseFileList($opt{'f'});
	} else {
		var_error();
	}
	if ($opt{'r'}) {
		@reverse_list = parseFileList($opt{'r'});
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

