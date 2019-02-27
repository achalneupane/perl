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
#	and summarizes the percent of reads / annotation for each file.
#	
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
	-i\tcombined sizeNT file(s)
	-o\tOutput file\n\n";

my (%opt, @infiles, $outfile);

getopts('i:o:', \%opt);
var_check();

open (OUT, ">$outfile") || die "Cannot open $outfile: $!\n\n"; 

my (@group, %total, %data, %catID_hash);

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
		next if ($line =~ /^\d/);
		chomp $line;
		
		my @split = split(/\t/, $line);
		my $catID = $split[3];
		my $reads = $split[1];
		
		$data{$group}{$catID} += $reads;
		$total{$group} += $reads;
		$catID_hash{$catID} = 1;
	}
	close IN;
	print STDERR " done.\n";
}

print OUT "Category\tData\tGroup\n";
print STDERR " Printing to outfile...";

foreach my $group (@group) {
	foreach my $catID (sort {$a cmp $b} keys %catID_hash) {
		print OUT "$catID";
		if (exists($data{$group}{$catID})) {
			my $total = $total{$group};
			my $count = $data{$group}{$catID};
			my $percent = sprintf("%.1f", $count / $total * 100);
			print OUT "\t$percent";
		} else {
			print OUT "\t0.0";
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
