#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use POSIX qw( ceil floor);
use DBI;
use Config::Tiny;
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
#	Same as readsPerFeature.strandedness.oct14.pl except output is by library_id (not total)
#
###########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -c\tConfig file
    -s\tSpecies
    -l\tLibrary IDs to use (i.e. -l 1-2 -l 1,2,4-6)
    -f\tFeatures file
    -o\tOutput filename
    ** Optional
    -C\tCatIDs to keep from -f features file for evaluation (default: 1,18-24,42,43,45,50 i.e. no strRNAs)
    -i\tFile with SIDs to include in the evaluation
    -r\tRange of sizes (default = 18-27)\n\n";

my (%opt, @list, $outfile, $species, $confFile, @range, $feat_file, %sizes, %libs, @catIDs, %catIDs);

getopts('l:o:s:c:r:f:C:h', \%opt);
var_check();

# Get configuration settings
my $Conf = Config::Tiny->read($confFile);
my $conf = $Conf->{$species};
my $sam = $Conf->{'PIPELINE'}->{'sam'};
my $bam = $conf->{'bam'};

# Connect to the SQLite database
my $dbh = DBI->connect("dbi:SQLite:dbname=$conf->{'db'}","","") or die "Can't connect to the database: $DBI::errstr\n";

foreach my $size (@range) {
	$sizes{$size} = 1;
}
foreach my $lib (@list) {
	$libs{$lib} = 1;
	print "Libraries: $lib\n";
}
foreach my $catID (@catIDs) {
	$catIDs{$catID} = 1;
	print "Category_IDs: $catID\n";
}

#########################################################
# End Variable declarations                             #
#########################################################

#########################################################
# Start Main body of Program                            #
#########################################################

my $count = 0;

open (OUT, ">$outfile") or die "Cannot open $outfile: $!\n\n";
print OUT "LibraryID\tFeatID\tCatID\tSenseReads\tAntiReads\tTotalReads\tLength\tGeneName\n";

my $sense_count = 0;
my $anti_count = 0;

$count = 0;
my $sth = $dbh->prepare('SELECT * FROM `reads` WHERE `sid` = ?') or die "Can't prepare SQL statement: $DBI::errstr\n";

my (%reads, %seqs);
foreach my $lib_id (@list) {
	$reads{'sense'}{$lib_id} = 0;
	$reads{'anti'}{$lib_id} = 0;
	$reads{'total'}{$lib_id} = 0;
}

print STDERR " Processing features... $count\r";

open (FEAT, $feat_file) or die " Cannot open $feat_file: $!\n\n";
while (my $line = <FEAT>) {
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
	
	open SAM, "$sam view $bam '$ref:$start-$end' |";
	while (my $line = <SAM>) {
		my @tmp = split /\t/, $line;
		my $sid = $tmp[0];
		
		my $read_strand = $tmp[1];
		my $strand_combo;
		
		if ($read_strand == 0 && $strand eq "sense") {
			$strand_combo = "sense";
		} elsif ($read_strand == 16 && $strand eq "anti") {
			$strand_combo = "sense";
		} elsif ($read_strand == 16 && $strand eq "sense") {
			$strand_combo = "anti";
		} elsif ($read_strand == 0 && $strand eq "anti") {
			$strand_combo = "anti";
		} else {
			print "$sid\tOther condition\n";
		}
		
		my $length = length($tmp[9]);
		next if (!exists($sizes{$length}));
		$sth->execute($sid) or die "Can't execute SQL statement: $DBI::errstr\n";
		while (my $row = $sth->fetchrow_hashref) {
			if (exists($libs{$row->{'library_id'}})) {
				my $lib_id = $row->{'library_id'};
				$reads{$strand_combo}{$lib_id} += $row->{'reads'};
				$reads{'total'}{$lib_id} += $row->{'reads'};
			}
		}
		warn "Data fetching terminated early by error: $DBI::errstr\n" if $DBI::err;
	}
	close SAM;
	foreach my $library_id (@list) {
		print OUT $library_id . "\t" . $featID."\t".$catID;
		print OUT "\t".$reads{'sense'}{$library_id}."\t".$reads{'anti'}{$library_id}."\t".$reads{'total'}{$library_id};
		print OUT "\t".$flength."\t".$accession . "\n";
	}
	print STDERR " Processing features... $count\r";
	$count++;
}
close FEAT;
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
	if ($opt{'l'}) {
		@list = parseListToArray($opt{'l'});
	} else {
		var_error();
	}
	if ($opt{'o'}) {
		$outfile = $opt{'o'};
	} else {
		var_error();
	}
	if ($opt{'c'}) {
		$confFile = $opt{'c'};
	} else {
		var_error();
	}
	if ($opt{'s'}) {
		$species = $opt{'s'};
	} else {
		var_error();
	}
	if ($opt{'r'}) {
		@range = parseListToArray($opt{'r'});
	} else {
		@range = parseListToArray('18-27');
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
