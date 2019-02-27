#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use POSIX qw( ceil floor);
use CommonFunctions qw(parseListToArray parseFileList);
use Statistics::R;
use Statistics::Descriptive;
use Cwd;
use Env qw(HOME);
use lib "$HOME/lib/perl";

#########################################################
# Start Variable declarations                           #
#########################################################

my @script_info = "
##########################################################################################
#
#	Script takes a list of indexed .bam files & a region of interest and determines
#	the densityPerNT. Script is specific to RNAseq data (ie no database) produced using dUTP method
#	(hit strand is flipped). The average hitsPerNT is determined, with or without normalization to
#	totalReads (-t), and a .pdf image is produced.	
#	
##########################################################################################
    \nYou did not provide enough information...  Usage: perl script_name.pl [OPTIONS]
    -b\tComma-separated list of indexed .bam file(s)
    -a\tAccession/contig/scaffold name (ie ChNRV1)
    -r\tCoordinate range on contig (ie 1-2923)
    -p\tOutfile prefix name (.pdf will be added to it)
    OPTIONAL:
    -h\tPrint this help menu
    -f\tAdditional features to be plotted --> comma-separated list (ie 1000-2000,3000-4000)
    -n\tNormalize count value to totalReads in totalReads_file
    -i\tIgnore strand information
    -M\tSet the max Y-axis value (overrides automatic min/max calculation) ***Must use -M & -m together
    -m\tSet the min Y-axis value (overrides automatic min/max calculation). For min y-axis of -10, input 10  ***Must use -M & -m together
    -c\tHex code for color of line for plotted data, without the '#' (default: black)\n\n";

my (%opt, %reads, $prefix, $accession, $range, @bam_files, $additional_features, @features, @x, @y1, @y2, $cmd, $user_max, $user_min, $totalReads_file, $user_color);

getopts('b:a:r:p:f:n::c:M:m:ih', \%opt);
var_check();

my $cwd = getcwd;
#Greys
my @colors = ('#CCCCCC','#999999','#666666','#333333');
my $pdf = "$prefix.pdf";

my ($start, $end) = split /-/, $range;
if (!$start || !$end) {
	var_error();
}

if ($additional_features ne 'none') {
	@features = split /,/, $additional_features;
}

my $total_reads = 1000000;	# Modified below if opt{'n'}
my $lib_count = scalar(@bam_files);

#########################################################
# End Variable declarations                             #
#########################################################

#########################################################
# Start Main body of Program                            #
#########################################################
my (%totalReads, $genotype, %colors);

if ($opt{'n'}) {
	open (NORM, $totalReads_file) || die "Cannot open $totalReads_file: $!\n\n";
	
	while (my $line = <NORM>) {
		next if ($line =~ /Group/);
		chomp $line;
		my ($group, $rep, $totalReads, $colors) = split(/\t/, $line);
		$totalReads{$group}{$rep} = $totalReads;
		$colors{$group} = $colors;
	}
	close NORM;
} else {
	print STDERR "No normalization\n";
}

for (my $x = $start; $x <= $end; $x++) {
	push @x, $x;
	push @y1, 0;
	push @y2, 0;
}

print STDERR " Going through bamfile(s) for region of interest... ";
my $counter = 1;

foreach my $bam_file (@bam_files) {
	open SAM, "samtools view $bam_file '$accession:$range' |";
	
	my @name = split(/\_/, $bam_file);
	
	my $group = $name[0];
	my $rep = $name[1];
	$genotype = $group;
	
	if ($opt{'n'}) {
		if (!exists($totalReads{$group}{$rep})) {
			print STDERR "\n$group\t$rep is not in $totalReads_file\n";
		} else {
			$total_reads = $totalReads{$group}{$rep};
		}
	}
	
	if (exists($colors{$group})) {
		$user_color = "#" . $colors{$group};
	}
	
	
	while (my $hit = <SAM>) {
		chomp $hit;
		my @tmp = split /\t/, $hit;
		
		for (my $p = $tmp[3]; $p < $tmp[3] + length($tmp[9]); $p++) {
			my $i = $p - $start;
			next if ($i >= scalar(@x));		
			
			if ($opt{'i'}) {
				$y1[$i] += (1 * 1000000 / $total_reads) / $lib_count;
			} else {
				if ($tmp[1] == 0) {
					$y1[$i] -= (1 * 1000000 / $total_reads) / $lib_count;
				} elsif ($tmp[1] == 16) {
					$y2[$i] += (1 * 1000000 / $total_reads) / $lib_count;
				}
			}
		}
	}
	close SAM;	
}
print STDERR "done\n";

print STDERR " Generating histogram... ";
my $R = Statistics::R->new();
$R->start();

my ($y_min, $y_max);
if ($opt{'M'}) {
	$y_min = $user_min * -1;
	$y_max = $user_max;
} else {
	my $stat = Statistics::Descriptive::Full->new();
	$stat->add_data((@y1,@y2));
	$y_max = $stat->max();
	$y_min = $stat->min();
}

if (!$opt{'i'} && !$opt{'M'}) {
	if ((abs($y_max) > abs($y_min)) || (abs($y_max) == abs($y_min) && $y_max > 0)) {
		$y_min = -$y_max;
	} elsif ((abs($y_min) > abs($y_max)) || (abs($y_max) == abs($y_min) && $y_max < 0)) {
		$y_max = abs($y_min);
	} else {
		print 'Something is wrong here:\n';
		print 'Y-max = '.$y_max."\n";
		print 'Y-max = '.$y_min."\n";
		exit 1;
	}
}

$cmd  = "x<-cbind(".join(",", @x).")\n";
$cmd .= "y1<-cbind(".join(",", @y2).")\n";
if (!$opt{'i'}) {
	$cmd .= "y2<-cbind(".join(",", @y1).")\n";
}
$cmd .= "pdf(file=\"$cwd/$pdf\",width=6,height=4,family=\"Helvetica\",paper=\"special\")\n";
$cmd .= "plot(x,y1,type='l',xaxt='n',yaxt='n',xlim=c($start,$end),ylim=c($y_min,$y_max),bty='n',xlab=NA,ylab='Average Reads / Million', col=\'$user_color\')\n";
$cmd .= "axis(side=1,pos=c($y_min,$start),lwd=1)\n";
$cmd .= "axis(side=2,pos=c($start,$y_min),lwd=1,las=1)\n";
if (!$opt{'i'}) {
	$cmd .= "points(x=x,y=y2,type='l',col=\'$user_color\')\n";
}
$cmd .= "lines(x=c($start,$end),y=c(0,0),lwd=0.5)\n";
$cmd .= "legend('topright', \'$genotype\', fill=\'$user_color\', horiz=TRUE, border='NA', bty='n')\n";

if (@features) {
	foreach my $feature (@features) {
		my ($x1, $x2) = split /-/, $feature;
		my $y_feat;
		if (abs($y_max) > abs($y_min)) {
			$y_feat = $y_min * -1;
		} else {
			$y_feat = $y_max;
		}
		
		my $y1 = $y_feat * 0.25 * -0.5;
		my $y2 = $y_feat * 0.25 * 0.5;
		my $color = shift(@colors);
		$cmd .= "rect(xleft=c($x1),xright=c($x2),ybottom=c($y1),ytop=c($y2),border=\'$color\',col='NA')\n";
		push @colors, $color;
	}
}
$cmd .= "dev.off()\n";
$R->run($cmd);
print STDERR "done\n";
my $errors = $R->error();
if ($errors =~ /^\s*$/) {
	print STDERR " Plotting completed without any errors\n";
} else {
	print STDERR "$errors\n";
}
$R->stop();
print STDERR "done\n";

exit;

#########################################################
# End Main body of Program                              #
#########################################################

#########################################################
# Start Subroutines                                     #
#########################################################

sub var_check {
	if ($opt{'h'}) {
		var_error();
	}
	if ($opt{'b'}) {
		@bam_files = parseFileList($opt{'b'});
	} else {
		var_error();
	}
	if ($opt{'p'}) {
		$prefix = $opt{'p'};
	} else {
		var_error();
	}
	if ($opt{'a'}) {
		$accession = $opt{'a'};
	} else {
		var_error();
	}
	if ($opt{'r'}) {
		$range = $opt{'r'};
	} else {
		var_error();
	}
	if ($opt{'M'}) {
		$user_max = $opt{'M'};
		if (!$opt{'m'}) {
			print STDERR "\n-m y-axis min must also be set\n";
		}
	}
	if ($opt{'m'}) {
		$user_min = $opt{'m'};
		if (!$opt{'M'}) {
			print STDERR "\n-M y-axis max must also be set\n";
		}
	}
	if ($opt{'f'}) {
		$additional_features = $opt{'f'};
	} else {
		$additional_features = 'none';
	}
	if ($opt{'n'}) {
		$totalReads_file = $opt{'n'};
	} 
	if ($opt{'c'}) {
		$user_color = "#";
		$user_color .= $opt{'c'};
	} else {
		$user_color = "#000000";
	}
}

sub var_error {
	print "@script_info";
	exit 1;
}

#########################################################
# End Subroutines                                       #
#########################################################
