#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use Cwd;
use FileHandle;
use Env qw(HOME);
use lib "$HOME/lib/perl";
use CommonFunctions qw(parseListToArray);

############## Begin variables ##############

my (%opt, $prefix, $r1, $r2, @indexList, %stats, $verbose, %idt, %index, %fh);
getopts('r:i:I:o:vh', \%opt);
var_check();

my $tmp = '/mnt/ramdisk';
my $cwd = getcwd();

# Initialize stats hash, stores summary statistics for the run
$stats{'total'} = 0;
$stats{'noindex'} = 0;
foreach my $tag (@indexList) {
	$stats{$tag} = 0;
	$index{$tag} = 1;
	$fh{$tag.'R1'} = FileHandle->new;
	open ($fh{$tag.'R1'}, ">".$tmp.'/'.$prefix."_".$tag."_R1.fastq") or die " Cannot open ".$tmp.'/'.$prefix."_".$tag."_R1.fastq\n";
}

my $log = $prefix.'.log';
open (LOG, ">$log") or die " Cannot open file $log: $!\n\n";


############## End variables ##############

############## Begin main program ##############

my $c = 0;
print STDERR " Demultiplexing index file... processed $c\r" if ($verbose);
open R2, "zcat $r2 |";
while (1) {
	# Get the next sequence from the index file (R2)
	my $head = <R2>;
	my $seq = <R2>;
	my $head2 = <R2>;
	my $qual = <R2>;
	chomp $seq;
	$stats{'total'}++;
	if (exists($index{$seq})) {
		$stats{$seq}++;
		my ($id, $pair) = split /\s+/, $head;
		$idt{$id} = $seq;
	} else {
		$stats{'noindex'}++;
	}
	$c++;
	print STDERR " Demultiplexing index file... processed $c\r" if ($verbose && ($c % 100000 == 0));
	last if (eof(R2));
}
close R2;

# Print out the run statistics
while (my ($k, $v) = each(%stats)) {
  print LOG $k." => ".$v."\n";
}
close LOG;
print STDERR " Demultiplexing index file... processed $c\n" if ($verbose);

$c = 0;
print STDERR " Demultiplexing forward reads... processed $c\r" if ($verbose);
open R1, "zcat $r1 |";
while (1) {
	# Get the next sequence from the reads file (R1)
	my $head = <R1>;
	my $seq = <R1>;
	my $head2 = <R1>;
	my $qual = <R1>;
	my ($id, $pair) = split /\s+/, $head;
	if (exists($idt{$id})) {
		my $tag = $idt{$id};
		print {$fh{$tag.'R1'}} ($id.'/1'."\n");
		print {$fh{$tag.'R1'}} ($seq);
		print {$fh{$tag.'R1'}} ($head2);
		print {$fh{$tag.'R1'}} ($qual);
	}
	$c++;
	print STDERR " Demultiplexing forward reads... processed $c\r" if ($verbose && ($c % 100000 == 0));
	last if (eof(R1));
}
close R1;
foreach my $tag (@indexList) {
	close $fh{$tag.'R1'};
	`gzip $tmp/$prefix\_$tag\_R1.fastq`;
	`mv $tmp/$prefix\_$tag\_R1.fastq.gz $cwd/$prefix\_$tag\_R1.fastq.gz`;	
}
print STDERR " Demultiplexing forward reads... processed $c\n" if ($verbose);

exit;

############## End main program ##############

############## Begin subroutines ##############

# var_check parses command-line options
# Activates var_error if required options missing, sets defaults
sub var_check {
  if ($opt{'h'}) {
    var_error();
  }
	# Required
  if ($opt{'r'}) {
    $r1 = $opt{'r'};
  } else {
    var_error();
  }
	if ($opt{'i'}) {
    $r2 = $opt{'i'};
  } else {
    var_error();
  }
	if ($opt{'o'}) {
    $prefix = $opt{'o'};
  } else {
    var_error();
  }
  if ($opt{'I'}) {
    @indexList = parseListToArray($opt{'I'});
  } else {
		var_error();
	}
	# Optional with defaults
	if ($opt{'v'}) {
    $verbose = 1;
  } else {
    # Verbose output is off by default
    $verbose = 0;
  }
}

# var_error prints out command-line options, defaults, optional settings
sub var_error {
  print STDERR "\n\n";
  print STDERR " This script will separate paired-end reads into library sets based on index sequences.\n";
  print STDERR " Usage: parsePEreads.pl -r <read1 file> -i <index file> -o <prefix> -I <index list>\n\n";
	print STDERR " REQUIRED:\n";
  print STDERR "   -r     Illumina R1 FASTQ file, gzipped.\n\n";
  print STDERR "   -i     Illumina R2 FASTQ file, gzipped.\n\n";
  print STDERR "   -o     Output file prefix.\n\n";
  print STDERR "   -I     Index sequence(s) list.\n\n";
  print STDERR "   -v     Verbose output. Prints program status to terminal. Default is quiet.\n\n";
  print STDERR "   -h     Print this menu\n\n";
  exit 1;
}
