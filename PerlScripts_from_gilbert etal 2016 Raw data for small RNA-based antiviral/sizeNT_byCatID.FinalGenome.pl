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

my @script_info = "
##########################################################################################
#
#	Modified June 13 to output sizeNT of SIDs that don't map to any features in the -f features file.
#
#	Script takes a features_table style input file and queries a database for the reads
#	that map to the regions in the input file. The 5'NT & size of the reads is the output.
#	Note: CatID >=1000 are automatically excluded.
#	Optional Flags:
#	-n: Normalization by RPM (total_reads in sqlite libraries table)
#
#	Output: Reads & Seqs / CatID, summarized for the LibIDs (therefore, run once / genotype).
#	
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -c\tPath to Config file
    -s\tSpecies name
    -f\tInput file (features_table)
    -l\tLibrary IDs (ie -l 1-4 or -l 14-15,24-25)
    -o\tOutput filename
    [Optional]
    -r\tRange of sizes (Default = 18-27 nt)
    -n\tOutput will be read counts normalized to reads mapped / 1,000,000; without -n raw read count and uniq seqs are the output\n\n";

my (%opt, @list, $outfile, $species, $confFile, @range, $features_file, $sth, %sizes, %libs);

getopts('l:o:s:c:r:f:nth', \%opt);
var_check();

# Get configuration settings
my $Conf = Config::Tiny->read($confFile);
my $conf = $Conf->{$species};
my $sam = $Conf->{'PIPELINE'}->{'sam'};
my $bam = $conf->{'bam'};

# Connect to the SQLite database
my $dbh = DBI->connect("dbi:SQLite:dbname=$conf->{'db'}","","") or die "Can't connect to the database: $DBI::errstr\n";
my ($totalReads, $rpm);

my $time = localtime();
print "Start time: $time\n";

if ($opt{'n'}) {
	print STDERR " Getting reads... \n";
	$sth = $dbh->prepare('SELECT * FROM `libraries` WHERE `library_id` = ?') or die "Can't prepare SQL statement: $DBI::errstr\n";
	foreach my $id (@list) {
		$sth->execute($id) or die "Can't execute SQL statement: $DBI::errstr\n";
		my $row = $sth->fetchrow_hashref;
		if ($row->{'total_reads'} > 0) {
			$totalReads += $row->{'total_reads'};
			print "Library: $id\tTotal Reads: $row->{'total_reads'}\n";
		} else {
			print STDERR " Total reads for library $id not set in $conf->{'db'}.libraries\n\n";
			exit 1;
		}
	}
	warn "Data fetching terminated early by error: $DBI::errstr\n" if $DBI::err;
} else {
	$totalReads = 1;
}
print STDERR " Total reads for normalization: $totalReads\n\n";
$rpm = 1000000 / $totalReads;

my ($max_size, $min_size);
$min_size = $range[0];

foreach my $size (@range) {
	$sizes{$size} = 1;
	$max_size = $size;
}
foreach my $lib (@list) {
	$libs{$lib} = 1;
}

open (OUT, ">$outfile") or die "Cannot open $outfile: $!\n\n";

open (IN, $features_file) || die "Cannot open $features_file: $!\n\n";
print STDERR " Getting SIDs mapped to CatIDs of Interest... \n";
my (@cat_array, %cat_track, %sid_hash);
my $count = 1;

while (my $line = <IN>) {
	chomp $line;
	
	my @split = split(/\t/, $line);
	my $featID = $split[0];
	my $catID = $split[1];

	print STDERR " Processed lines... $count\r" if ($count % 1000 == 0);

	next if ($catID >=2 && $catID <= 6);
	next if ($catID >= 1000);
	
	my $ref = $split[5];
	my $start = $split[8];
	my $end = $split[9];

	open SAM, "$sam view $bam '$ref:$start-$end' |";
	while (my $line = <SAM>) {
		my @tmp = split /\t/, $line;
		my $sid = $tmp[0];
		
		next if ($sid_hash{$sid}{$catID});
		$sid_hash{$sid}{$catID} = 1;
	}
	close SAM;
	
	if (!exists($cat_track{$catID})) {
		push(@cat_array, $catID);
	}
	
	$cat_track{$catID} = 1;
	$count++;
}
close IN;
my $noAnn = "0";
push(@cat_array, $noAnn);

@cat_array = sort(@cat_array);

print STDERR "\n Getting SIDs mapped to CatIDs of Interest... done\n";

my @nt = qw (A C G T);
my @kinds = qw (reads seqs);
my (%sizeNT, %nt, %size, @sizeNT);

for (my $i = 0; $i < scalar(@range); $i++) {
	for (my $n = 0; $n < 4; $n++) {
		for (my $k = 0; $k < scalar(@kinds); $k++) {
			my $sizeNT = $range[$i] . "_" . $nt[$n];
			if ($k == 0) {
				push (@sizeNT, $sizeNT);
			}
			
			foreach my $catID (@cat_array) {
				$sizeNT{$sizeNT}{$catID}{$kinds[$k]} = 0;			
				$nt{$nt[$n]}{$catID}{$kinds[$k]} = 0;
			}
			
		}
	}
	for (my $k = 0; $k < scalar(@kinds); $k++) {
		foreach my $catID (@cat_array) {
			$size{$range[$i]}{$catID}{$kinds[$k]} = 0;
		}
	}
}

#########################################################
# End Variable declarations                             #
#########################################################

#########################################################
# Start Main body of Program                            #
#########################################################

my $line_count = 1;
my $bad_size = 0;
my $bad_reads = 0;

print STDERR " Getting total read counts + sizeNT info... ";
$sth = $dbh->prepare('SELECT * FROM `reads` NATURAL JOIN `sequences` WHERE `library_id` = ?') or die "Can't prepare SQL statement: $DBI::errstr\n";
foreach my $library (@list) {
	$sth->execute($library) or die "Can't execute SQL statement: $DBI::errstr\n";
	
	while(my $row = $sth->fetchrow_hashref){
		my $sid = $row->{'sid'};
		my $seq = $row->{'seq'};
		
		my $len = length($seq);
		if ($len > $max_size || $len < $min_size) {
			$bad_size += 1;
			$bad_reads += $row->{'reads'};
			next;
		}
		
		my $nt = substr($seq, 0, 1);
		my $sizeNT = $len . "_" . $nt;
		
		if (!exists($sid_hash{$sid})) {
			my $catID = "0";
			
			$nt{$nt}{$catID}{'reads'} += $row->{'reads'};
			$nt{$nt}{$catID}{'seqs'} += 1;
			
			$size{$len}{$catID}{'reads'} += $row->{'reads'};
			$size{$len}{$catID}{'seqs'} += 1;
			
			$sizeNT{$sizeNT}{$catID}{'reads'} += $row->{'reads'};
			$sizeNT{$sizeNT}{$catID}{'seqs'} += 1;
			next;
		}
		
		my @catIDs;
		foreach my $catID (keys %{$sid_hash{$sid}}) {
			$nt{$nt}{$catID}{'reads'} += $row->{'reads'};
			$nt{$nt}{$catID}{'seqs'} += 1;
			
			$size{$len}{$catID}{'reads'} += $row->{'reads'};
			$size{$len}{$catID}{'seqs'} += 1;
			
			$sizeNT{$sizeNT}{$catID}{'reads'} += $row->{'reads'};
			$sizeNT{$sizeNT}{$catID}{'seqs'} += 1;
		}	
	}
	warn "Data fetching terminated early by error: $DBI::errstr\n" if $DBI::err;
}
%sid_hash = ();
print STDERR "done\n";
print " Total SIDs excluded due to size restrictions:\t$bad_size\n Total Reads excluded due to size restrictions:\t$bad_reads\n";

print STDERR " Printing to outfile... ";
print OUT "Length";
foreach my $catID (@cat_array) {
	print OUT "\tCatID$catID" . "_Reads\tCatID$catID" . "_Seqs";
}
print OUT "\n";

for (my $i = 0; $i < scalar(@range); $i++) {
	print OUT "$range[$i]";
	foreach my $catID (@cat_array) {
		foreach my $read_seq (@kinds) {
			if ($opt{'n'} && $read_seq =~ /reads/) {
				my $norm_reads = sprintf("%.2f", $size{$range[$i]}{$catID}{$read_seq} * $rpm);
				print OUT "\t$norm_reads";
			} else {
				my $all_seqs = $size{$range[$i]}{$catID}{$read_seq};
				print OUT "\t$all_seqs";
			}
		}
	}
	print OUT "\n";
}

print OUT "NT";
foreach my $catID (@cat_array) {
	print OUT "\tCatID$catID" . "_Reads\tCatID$catID" . "_Seqs";
}
print OUT "\n";

for (my $i = 0; $i < scalar(@nt); $i++) {
	print OUT "$nt[$i]";
	
	foreach my $catID (@cat_array) {
		foreach my $read_seq (@kinds) {
			if ($opt{'n'} && $read_seq =~ /reads/) {
				my $norm_reads = sprintf("%.2f", $nt{$nt[$i]}{$catID}{$read_seq} * $rpm);
				print OUT "\t$norm_reads";
			} else {
				print OUT "\t$nt{$nt[$i]}{$catID}{$read_seq}";
			}
		}
	}
	print OUT "\n";
}

print OUT "SizeNT";
foreach my $catID (@cat_array) {
	print OUT "\tCatID$catID" . "_Reads\tCatID$catID" . "_Seqs";
}
print OUT "\n";

for (my $i = 0; $i < scalar(@sizeNT); $i++) {
	print OUT "$sizeNT[$i]";
	my $sizeNT = $sizeNT[$i];
	
	foreach my $catID (@cat_array) {
		foreach my $read_seq (@kinds) {
			if ($opt{'n'} && $read_seq =~ /reads/) {
				my $norm_reads = sprintf("%.2f", $sizeNT{$sizeNT}{$catID}{$read_seq} * $rpm);
				print OUT "\t$norm_reads";
			} else {
				print OUT "\t$sizeNT{$sizeNT}{$catID}{$read_seq}";
			}
		}
	}
	print OUT "\n";
}

print STDERR " done\n";
close OUT;

$time = localtime();
print "End time: $time\n";
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
		$features_file = $opt{'f'};
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
