#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use POSIX qw( ceil floor);
use DBI;
use CommonFunctions qw(parseListToArray parseFileList);

my @script_info = "
##########################################################################################
#
#	Script takes a list of chromNum (ie 1,10236 for Supercontig1 and ChNRV1 respectively)
#	and outputs the RawReadCount of the SIDs that map to the feature(s) UNIQUELY.
#	chromNum	RawReadCount
#
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -d\tPath to sqlite database
    -b\tPath to .bam file for the database
    -l\tLibrary IDs
    -c\tList of chromNums
    -o\tOutput file name\n\n";

my (%opt, $outfile, $database, @list, $bam, @chromNums);

getopts('d:l:b:o:c:', \%opt);
var_check();

open (OUT, ">$outfile") || die "Cannot open $outfile: $!\n\n";

my %chromNums;
print " Features to find:\n";
foreach my $type (@chromNums) {
	$chromNums{$type} = 1;
	print "\t$type\n";
}

# Connect to database, initialize database handler
my $dbh = DBI->connect("dbi:SQLite:dbname=$database","","") or die "Can't connect to the database: $DBI::errstr\n";

my %sids;

print STDERR " Getting SIDs that map to the features above...\n";
my $line_count = 0;
foreach my $chromNum (@chromNums) {
	$line_count = 0;
	open (SAM, "samtools view $bam $chromNum |");
	while (my $sam = <SAM>) {
		chomp $sam;
		my @get_sid = split(/\t/, $sam);
		my $sid = $get_sid[0];
		$sids{$sid}{$chromNum} = 1;
		
		$line_count++;
	}
	close SAM;
	
	if ($line_count == 0) {
		print STDERR "No SIDs found for $chromNum. May want to check it is a valid chromAccession\n";
		$chromNums{$chromNum} = 1;
	}
	print STDERR " Line count $chromNum: $line_count\n";
}
print STDERR " Getting SIDs that map to the features above...done.\n";

#	Go through and delete sids from hash that map to other chromNums
my %seq;
print STDERR " Removing SIDs that map to other chromNums...";
open (SAM, "samtools view $bam |");
my $delete_count = 0;
while (my $sam = <SAM>) {
	chomp $sam;
	my @get_sid = split(/\t/, $sam);
	my $sid = $get_sid[0];
	my $chromNum = $get_sid[2];
	next if (exists($chromNums{$chromNum}));
	
	if (exists($sids{$sid})) {
		delete($sids{$sid});
		$delete_count++;
		next;
	}
}
close SAM;
print STDERR " done.\n";
print STDERR " Removed $delete_count SIDs due to multiple mappings\n";

#	Get a proper library name for header of output file [assumes doing 1 genotype at a time]
my $sth = $dbh->prepare("SELECT * FROM `libraries` WHERE `library_id` = ? ") or die "Can't prepare SQL statement: $DBI::errstr\n";
my $libID = $list[0];
$sth->execute($libID) or die "Can't execute SQL statement: $DBI::errstr\n";
my $header;
while(my $row = $sth->fetchrow_hashref){
	my @code =  split(/\_/, $row->{'code'});
	$header = $code[0];
}
warn "Data fetching terminated early by error: $DBI::errstr\n" if $DBI::err;

my (%sid_hash, %seq_track);
print STDERR " Getting reads information from reads table...\n";

$sth = $dbh->prepare("SELECT * FROM `reads` WHERE `library_id` = ? ") or die "Can't prepare SQL statement: $DBI::errstr\n";
foreach my $library_id (sort {$a <=> $b} @list) {
	print STDERR "  Getting reads for library $library_id... ";
	$sth->execute($library_id) or die "Can't execute SQL statement: $DBI::errstr\n";
	while(my $row = $sth->fetchrow_hashref){
		my $sid =  $row->{'sid'};
		next if (!exists($sids{$sid}));
		
		my $reads = $row->{'reads'};
		
		foreach my $chromNum (keys %{$sids{$sid}}) {
			$sid_hash{$chromNum} += $reads;
		}
	}
	warn "Data fetching terminated early by error: $DBI::errstr\n" if $DBI::err;
	print STDERR "done\n";
}
print STDERR " Getting reads information from reads table...done.\n";

foreach my $chromNum (@chromNums) {
	print STDERR "Reads: $sid_hash{$chromNum}\n";
}

print STDERR " Printing to outfile...";
print OUT "ChromNum\t$header\n";
foreach my $chromNum (@chromNums) {
	print OUT "$chromNum\t";
	my $reads = $sid_hash{$chromNum};
	print OUT "$reads\n";
}
close OUT;
print STDERR " done.\n";
$dbh->disconnect or warn "Error disconnecting: $DBI::errstr\n";
exit 0;

#########################################################
# Start of Varriable Check Subroutine "var_check"       #
#########################################################

sub var_check {
	if ($opt{'d'}) {
		$database = $opt{'d'};
	} else {
		var_error();
	}
	if ($opt{'b'}) {
		$bam = $opt{'b'};
	} else {
		var_error();
	}
	if ($opt{'o'}) {
		$outfile = $opt{'o'};
	} else {
		var_error();
	}
	if ($opt{'c'}) {
		@chromNums = parseListToArray($opt{'c'});
	} else {
		var_error();
	}
	if ($opt{'l'}) {
		@list = parseListToArray($opt{'l'});
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
