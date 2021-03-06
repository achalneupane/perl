#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use CommonFunctions qw(parseListToArray parseFileList);

#########################################################
# Start Variable declarations                           #
#########################################################

my @script_info = "
##########################################################################################
#
#	Script takes a list of files from combined_sizeNT (ie create_catID_sizeNT_summaries.pl)
#	and Category of interest and creates an output that is the reads data in 'long' formatted for
#	plotting in R.
#
#	Category list to choose from:
#	noAnn
#	gene
#	strRNA
#	TE
#	RE
#	virus
#	
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
	-i\tcombined sizeNT file(s)
	-c\tCategory of interest
	-o\tOutput file\n\n";

my (%opt, @infiles, @catIDs, $outfile);

getopts('i:o:c:', \%opt);
var_check();

open (OUT, ">$outfile") || die "Cannot open $outfile: $!\n\n"; 

my (@group, %catIDs, %nt_hash);
my @nts = qw (A C G U);

foreach my $cats (@catIDs) {
	$catIDs{$cats} = 1;
}

foreach my $file (@infiles) {
	open (IN, $file) or die " Cannot open $file: $!\n\n";
	my @name = split(/\_/, $file);
	my $group = $name[0];
	if ($file =~ /input/ || $file =~ /IP/) {
		my $add = $name[1];
		$group .= $add;
	}
	
	push(@group, $group);
	
	print STDERR " Working with $file...";
	while (my $line = <IN>) {
		next if ($line =~ /^Length/);
		next if ($line !~ /(\d+)/);
		chomp $line;
		
		my @split = split(/\t/, $line);
		my $cat = $split[3];
		next if (!exists($catIDs{$cat}));
		
		my $nt = $split[0];
		if ($nt eq "T") {
			$nt = "U";
		}
		
		my $reads = $split[1];
		my $seqs = $split[2];
		
		$nt_hash{$group}{$nt} = $reads;
	}
	close IN;
	print STDERR " done.\n";
}

print OUT "NT\tRPM\tGroup\n";
print STDERR " Printing to outfile...";

foreach my $group (@group) {
	foreach my $nt (@nts) {
		print OUT "$nt";
		if (exists($nt_hash{$group}{$nt})) {
			my $count = $nt_hash{$group}{$nt};
			print OUT "\t$count";
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
# Start Subroutines                                     #
#########################################################

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
		@infiles = parseFileList($opt{'i'});
	} else {
		var_error();
	}
	if ($opt{'c'}) {
		@catIDs = parseListToArray($opt{'c'});
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
	print "@script_info";
	exit 1;
}

#########################################################
# End of Varriable error Subroutine "var_error"         #
#########################################################
