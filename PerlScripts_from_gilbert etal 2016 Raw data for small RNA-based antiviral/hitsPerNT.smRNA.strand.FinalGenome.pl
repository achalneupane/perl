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

my @script_info = "
##########################################################################################
#
#	Script determined the coverage / basepair in	the region of interest for the libraries of interest.
#	Specific for smRNA data. Will average together all the -l library_ids normalized read counts.
#
#	Output:
#	Col1		Col2
#	pos1		count1
#	...		...
#	posN		countN
#
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -c\tConfig file
    -s\tSpecies from config file
    -l\tLibrary IDs (ie -l 6-8 or -l 14,15,20,21)
    -r\tRegion of interest (i.e. contigName:start-end)
    -o\toutput file\n\n";

#########################################################
# Start Variable declarations                           #
#########################################################

my (%opt, $species, $confFile, $outfile, @list, $region, $sth, %rpm);
getopts('c:s:l:r:o:n', \%opt);
var_check();

# Get configuration settings
my $Conf = Config::Tiny->read($confFile);
my $conf = $Conf->{$species};
my $sam = $Conf->{'PIPELINE'}->{'sam'};
my $bam = $conf->{'bam'};
#print "bam file: $bam";

# Connect to the SQLite database
my $dbh = DBI->connect("dbi:SQLite:dbname=$conf->{'db'}","","") or die "Can't connect to the database: $DBI::errstr\n";
my ($totalReads, $rpm);
#my (%total_reads);

my $time = localtime();
print "Start time: $time\n";

# Connect to the SQLite database
$sth = $dbh->prepare('SELECT * FROM `libraries` WHERE `library_id` = ?');
foreach my $id (@list) {
	$sth->execute($id);
	my $row = $sth->fetchrow_hashref;
	if ($row->{'total_reads'} > 0) {
		my $total_reads = $row->{'total_reads'};
		$totalReads += $total_reads;
		print "Library: $id\tTotal Reads: $row->{'total_reads'}\n";
	} else {
		print STDERR " Total reads for library $id not set in $conf->{'db'}.libraries\n\n";
		exit 1;
	}
}

$rpm = 1000000 / $totalReads;
print STDERR " RPM for normalization: $rpm\n";

my $lib_total = scalar(@list);

#########################################################
# Start Main body of Program                            #
#########################################################

my (%hash, %pos, $start, $end, %sids);
my @dirs = qw (for rev);
my @pos;

if ($region =~ /\:/) {
	my @tmp = split(/\-/, $region);
	$end = $tmp[1];
	my @split2 = split(/\:/, $tmp[0]);
	$start = $split2[1];
	
	push(@pos, $tmp[1]);
	push(@pos, $split2[1]);
} else {
	print STDERR "Incorrect $region, need coordinates\n";
	exit;
}

$sth = $dbh->prepare('SELECT * FROM `reads` WHERE `library_id` = ?') or die "Can't prepare SQL statement: $DBI::errstr\n";
foreach my $library (@list) {
	print STDERR " Getting sids from library $library\r";
	$sth->execute($library) or die "Can't execute SQL statement: $DBI::errstr\n";
	
	while(my $row = $sth->fetchrow_hashref){
		my $sid = $row->{'sid'};
		my $reads = $row->{'reads'};
		$sids{$sid} += $reads;  
	}
	warn "Data fetching terminated early by error: $DBI::errstr\n" if $DBI::err;
	print STDERR " Getting sids from library $library Done.\n";
}

print STDERR " Getting sids from region... \n";

open (OUT, ">$outfile") || die "Cannot open outfile: $outfile: $!\n\n";

open BAM, "samtools view $bam $region |";
while (my $line = <BAM>) {
	chomp $line;
	
	my @split = split(/\t/, $line);
	my $strand = $split[1];
	if ($strand == 16) {
		$strand = "rev";
	} else {
		$strand = "for";
	}
	
	my $hit_start = $split[3];
	my $len = length($split[9]);
	
	my $sid = $split[0];
	
	my $reads;
	if (exists($sids{$sid})) {
		$reads = $sids{$sid};
	} else {
		$reads = 0;
	}
	for (my $i = $hit_start; $i < ($hit_start + $len); $i++) {
		$hash{$i}{$strand} += $reads;
	}
}
close BAM;

#	Header line
print OUT "Pos";
foreach my $dir (@dirs) {
	my $header = $dir;
	print OUT "\t$header";
}
print OUT "\n";

for (my $pos = $start; $pos <= $end; $pos++) {
	print OUT "$pos";
	foreach my $dir (@dirs) {
		if (exists($hash{$pos}{$dir})) {
			my $norm_reads = $hash{$pos}{$dir} * $rpm;
			my $avg_reads = sprintf("%.1f", ($norm_reads / $lib_total));
			print OUT "\t$avg_reads";
		} else {
			print OUT "\t0.0";
		}
	}
	print OUT "\n";
}
close OUT;
exit;


#########################################################
# Start of Varriable Check Subroutine "var_check"       #
#########################################################

sub var_check {
	if ($opt{'r'}) {
		$region = $opt{'r'};
	} else {
		&var_error();
	}
	if ($opt{'s'}) {
		$species = $opt{'s'};
	} else {
		&var_error();
	}
	if ($opt{'c'}) {
		$confFile = $opt{'c'};
	} else {
		&var_error();
	}
	if ($opt{'o'}) {
		$outfile = $opt{'o'};
	} else {
		&var_error();
	}
	if ($opt{'l'}) {
		@list = parseListToArray($opt{'l'});
	} else {
		var_error();
	}
}

sub var_error {
	print "@script_info";
	exit 0;
}
exit;
