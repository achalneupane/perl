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
#	Script takes a features_table style input file and queries a database for the reads
#	that map to the regions in the input file. The 5'NT & size of the reads by strand is the output.
#
#	Note: CatID >=1000 are automatically excluded.
#	Optional Flags:
#	-n: Normalization by RPM
#	-r: Range of sizes
#	-C: CatIDs to query
#
#	Output: Reads & Seqs / CatID, per LibID.
#	
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -c\tPath to Config file
    -s\tSpecies name
    -f\tInput file (features_table)
    -l\tLibrary IDs (ie -l 1-4 or -l 14-15,24-25)
    -o\tOutput filename
    -S\tStrand to query (FF (CatID=F,Reads=F), FR (CatID=F,Reads=R), RF, RR)
    [Optional]
    -r\tRange of sizes (Default = 18-30nt)
    -n\tOutput will be read counts normalized to reads mapped / 1,000,000; without -n raw read count and uniq seqs are the output
    -C\tCategory IDs (default: 1,18-24,42,43,45,50 ie no strRNAs)
    -N\tInclude regions of No annotation (default: not included)\n\n";

my (%opt, @list, $outfile, $species, $confFile, @range, $features_file, $sth, %sizes, %libs, %catIDs, @catIDs, $strand);

getopts('l:o:s:c:r:f:C:S:nh', \%opt);
var_check();

# Get configuration settings
my $Conf = Config::Tiny->read($confFile);
my $conf = $Conf->{$species};
my $sam = $Conf->{'PIPELINE'}->{'sam'};
my $bam = $conf->{'bam'};

# Connect to the SQLite database
my $dbh = DBI->connect("dbi:SQLite:dbname=$conf->{'db'}","","") or die "Can't connect to the database: $DBI::errstr\n";
my ($totalReads, $rpm);
my (%total_reads);

my $time = localtime();
print "Start time: $time\n";

if ($opt{'n'}) {
	print STDERR " Getting reads... \n";
	$sth = $dbh->prepare('SELECT * FROM `libraries` WHERE `library_id` = ?') or die "Can't prepare SQL statement: $DBI::errstr\n";
	foreach my $id (@list) {
		$sth->execute($id) or die "Can't execute SQL statement: $DBI::errstr\n";
		my $row = $sth->fetchrow_hashref;
		if ($row->{'total_reads'} > 0) {
			$total_reads{$id} += $row->{'total_reads'};
			#$totalReads += $row->{'total_reads'};
			print "Library: $id\tTotal Reads: $total_reads{$id}\n";
		} else {
			print STDERR " Total reads for library $id not set in $conf->{'db'}.libraries\n\n";
			exit 1;
		}
	}
	warn "Data fetching terminated early by error: $DBI::errstr\n" if $DBI::err;
} else {
	$totalReads = 1;
}
#print STDERR " Total reads for normalization: $totalReads\n\n";
#$rpm = 1000000 / $totalReads;

my ($max_size, $min_size);
$min_size = $range[0];

foreach my $size (@range) {
	$sizes{$size} = 1;
	$max_size = $size;
}
foreach my $lib (@list) {
	$libs{$lib} = 1;
}
my @sort_catIDs;
foreach my $catID (@catIDs) {
	$catIDs{$catID} = 1;
	if($opt{'N'}) {
		$catIDs{'0'} = 1;
		push @catIDs, 0;
		@sort_catIDs = sort {$a <=> $b} @catIDs;
		@catIDs = @sort_catIDs;
	}
}

open (OUT, ">$outfile") or die "Cannot open $outfile: $!\n\n";

open (IN, $features_file) || die "Cannot open $features_file: $!\n\n";
print STDERR " Getting SIDs mapped to CatIDs of Interest... \n";
#my (@cat_array, %cat_track, %sid_hash);
my %sid_hash;
my $count = 1;

while (my $line = <IN>) {
	chomp $line;
	
	my @split = split(/\t/, $line);
	my $featID = $split[0];
	my $catID = $split[1];

	print STDERR " Processed lines... $count\r" if ($count % 1000 == 0);

	next if (!exists($catIDs{$catID}));
	
	my $ref = $split[5];
	my $start = $split[8];
	my $end = $split[9];
	my $feat_strand = $split[10];
	my $bam_flag;
	
	if ($feat_strand == 1 && $strand eq "FF") {
		$bam_flag = "-F 16 ";
	} elsif ($feat_strand == 1 && $strand eq "FR") {
		$bam_flag = "-f 16 ";
	} elsif ($feat_strand == -1 && $strand eq "RR") {
		$bam_flag = "-f 16 ";
	} else {
		$bam_flag = "-F 16 ";
	}
 
	open SAM, "$sam view $bam_flag $bam '$ref:$start-$end' |";
	while (my $line = <SAM>) {
		my @tmp = split /\t/, $line;
		my $sid = $tmp[0];
		
		next if ($sid_hash{$sid}{$catID});
		$sid_hash{$sid}{$catID} = 1;
	}
	close SAM;
	$count++;
}
close IN;
#my $noAnn = "0";
#push(@cat_array, $noAnn);

#@cat_array = sort(@cat_array);

print STDERR "\n Getting SIDs mapped to CatIDs of Interest... done\n";

my @nt = qw (A C G T);
my @kinds = qw (reads);
#my @kinds = qw (reads seqs);
my (%sizeNT, %nt, %size, @sizeNT);

foreach my $libID (@list) {
	for (my $i = 0; $i < scalar(@range); $i++) {
		for (my $n = 0; $n < 4; $n++) {
			for (my $k = 0; $k < scalar(@kinds); $k++) {
				my $sizeNT = $range[$i] . "_" . $nt[$n];
				if ($k == 0) {
					push (@sizeNT, $sizeNT);
				}
				
				foreach my $catID (@catIDs) {
					$sizeNT{$sizeNT}{$catID}{$kinds[$k]}{$libID} = 0;			
					$nt{$nt[$n]}{$catID}{$kinds[$k]}{$libID} = 0;
					
					if ($opt{'t'}) {
						$sizeNT{$sizeNT}{$catID}{$kinds[$k]}{$libID} = 0;
						$nt{$nt[$n]}{$catID}{$kinds[$k]}{$libID} = 0;
					}
				}
			}
		}
		for (my $k = 0; $k < scalar(@kinds); $k++) {
			foreach my $catID (@catIDs) {
				$size{$range[$i]}{$catID}{$kinds[$k]}{$libID} = 0;
				
				if ($opt{'t'}) {
					$size{$range[$i]}{$catID}{$kinds[$k]}{$libID} = 0;
				}
			}
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
#my $bad_size = 0;
#my $bad_trim = 0;
#my $bad_reads = 0;

print STDERR " Getting total read counts + sizeNT info... ";
$sth = $dbh->prepare('SELECT * FROM `reads` NATURAL JOIN `sequences` WHERE `library_id` = ?') or die "Can't prepare SQL statement: $DBI::errstr\n";
foreach my $library (@list) {
	$sth->execute($library) or die "Can't execute SQL statement: $DBI::errstr\n";
	
	while(my $row = $sth->fetchrow_hashref){
		my $sid = $row->{'sid'};
		my $seq = $row->{'seq'};
		next if (!exists($sid_hash{$sid}) && !$opt{'N'});
		
		my $len = length($seq);
		if ($len > $max_size || $len < $min_size) {
			#$bad_size += 1;
			#$bad_reads += $row->{'reads'};
			next;
		}
		
		my $nt = substr($seq, 0, 1);
		my $sizeNT = $len . "_" . $nt;
		
		if (!exists($sid_hash{$sid}) && $opt{'N'}) {
			my $catID = "0";
			
			$nt{$nt}{$catID}{'reads'}{$library} += $row->{'reads'};
			$nt{$nt}{$catID}{'seqs'}{$library} += 1;
			
			$size{$len}{$catID}{'reads'}{$library} += $row->{'reads'};
			$size{$len}{$catID}{'seqs'}{$library} += 1;
			
			$sizeNT{$sizeNT}{$catID}{'reads'}{$library} += $row->{'reads'};
			$sizeNT{$sizeNT}{$catID}{'seqs'}{$library} += 1;
			next;
		}
		my @catIDs;
		foreach my $catID (keys %{$sid_hash{$sid}}) {
			# The number of reads from the trim table & the total number of reads from the reads table are recorded here; later, if "opt{'t'}", then math
			# is done to get the value for "full length reads";
			
			$nt{$nt}{$catID}{'reads'}{$library} += $row->{'reads'};
			$nt{$nt}{$catID}{'seqs'}{$library} += 1;
			
			$size{$len}{$catID}{'reads'}{$library} += $row->{'reads'};
			$size{$len}{$catID}{'seqs'}{$library} += 1;
			
			$sizeNT{$sizeNT}{$catID}{'reads'}{$library} += $row->{'reads'};
			$sizeNT{$sizeNT}{$catID}{'seqs'}{$library} += 1;
		}	
	}
	warn "Data fetching terminated early by error: $DBI::errstr\n" if $DBI::err;
}
%sid_hash = ();
print STDERR "done\n";
#print " Total SIDs excluded due to size restrictions:\t$bad_size\n Total Reads excluded due to size restrictions:\t$bad_reads\n";

print STDERR " Printing to outfile... ";
my @hash_refs;
@hash_refs = qw (all);

print OUT "Length";
foreach my $libID (@list) {
	foreach my $catID (@catIDs) {
		print OUT "\tCatID$catID" . "_lib$libID";
	}
}
print OUT "\tTotal\n";

for (my $i = 0; $i < scalar(@range); $i++) {
	print OUT "$range[$i]";
	my $Total = 0;
	foreach my $catID (@catIDs) {
		foreach my $read_seq (@kinds) {
			foreach my $libID (@list) {
				if ($opt{'n'} && $read_seq =~ /reads/) {
					$rpm = 1000000 / $total_reads{$libID};
					my $norm_reads = sprintf("%.2f", $size{$range[$i]}{$catID}{$read_seq}{$libID} * $rpm);
					print OUT "\t$norm_reads";
					$Total += $norm_reads;
				} else {
					my $all_seqs = $size{$range[$i]}{$catID}{$read_seq}{$libID};
					print OUT "\t$all_seqs";
				}
			}
		}
	}
	print OUT "\t$Total\n";
}

print OUT "NT";
foreach my $libID (@list) {
	foreach my $catID (@catIDs) {
		print OUT "\tCatID$catID" . "_lib$libID";
	}
}
print OUT "\tTotal\n";

for (my $i = 0; $i < scalar(@nt); $i++) {
	print OUT "$nt[$i]";
	my $Total = 0;
	
	foreach my $catID (@catIDs) {
		foreach my $read_seq (@kinds) {
			foreach my $libID (@list) {
				if ($opt{'n'} && $read_seq =~ /reads/) {
					$rpm = 1000000 / $total_reads{$libID};
				my $norm_reads = sprintf("%.2f", $nt{$nt[$i]}{$catID}{$read_seq}{$libID} * $rpm);
				$Total += $norm_reads;
				print OUT "\t$norm_reads";
				} else {
					print OUT "\t$nt{$nt[$i]}{$catID}{$read_seq}{$libID}";
				}
			}
		}
	}
	print OUT "\t$Total\n";
}

print OUT "SizeNT";
foreach my $libID (@list) {
	foreach my $catID (@catIDs) {
		print OUT "\tCatID$catID" . "_lib$libID";
	}
}
print OUT "\tTotal\n";

for (my $i = 0; $i < scalar(@sizeNT); $i++) {
	print OUT "$sizeNT[$i]";
	my $sizeNT = $sizeNT[$i];
	my $Total = 0;
	
	foreach my $catID (@catIDs) {
		foreach my $read_seq (@kinds) {
			foreach my $libID (@list) {
				if ($opt{'n'} && $read_seq =~ /reads/) {
					$rpm = 1000000 / $total_reads{$libID};
					my $norm_reads = sprintf("%.2f", $sizeNT{$sizeNT}{$catID}{$read_seq}{$libID} * $rpm);
					print OUT "\t$norm_reads";
					$Total += $norm_reads;
				} else {
					print OUT "\t$sizeNT{$sizeNT}{$catID}{$read_seq}{$libID}";
				}
			}
		}
	}
	print OUT "\t$Total\n";
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
	if ($opt{'C'}) {
		@catIDs = parseListToArray($opt{'C'});
	} else {
		@catIDs = parseListToArray('1,18-24,42,43,45,50');
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
	if ($opt{'S'}) {
		$strand = $opt{'S'};
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
