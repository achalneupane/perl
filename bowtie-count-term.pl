
# usage ./bowtie-count-term.pl infile class

my $sread = "ACGT-read";
my $strand ="-";
my $name = "bill";
my $position = 1;
my $sequence = "ACGT";
my $quality = "good";
my $d2 = "d2";
my $d3 = "d3";
my $class= $ARGV[1];
my @mray;
my @lines;
my $min = 10;

for (my $i=0; $i < $class; $i++) {
    $mray[$i][0]=0;
    $mray[$i][1]=0;
    $mray[$i][2]=0;
    $mray[$i][3]=0;
}

open (INFILE, "<$ARGV[0]") || die "couldn't open the 1 infile!";

while ($rln = <INFILE>){
	chomp $rln;
	($sread, $strand, $name, $position, $sequence, $quality, $d2,$d3) = split("\t",$rln);
    $seq_len = length ($sequence);
    if ($seq_len == $class && $d3){
       ($position, $d2) = split(":",$d3);
       $var = substr $d2, -1;
       if ($var eq "A" ) { $mray[$position][0]++ }
       if ($var eq "C" ) { $mray[$position][1]++ }
       if ($var eq "G" ) { $mray[$position][2]++ }
       if ($var eq "T" ) { $mray[$position][3]++ }
       if ($position == ($class-1)) {
           $read = substr $sequence, 0, $class-1;
           push (@lines, $read);
       }
    }
}
close (INFILE);
print "Pos\tA\tC\tG\tT\n";
for (my $i=0; $i < $class; $i++) {
    $pnum = $i + 1;
    print "$pnum\t$mray[$i][0]\t$mray[$i][1]\t$mray[$i][2]\t$mray[$i][3]\n";
}

@lines = sort(@lines); # sort the list
$count = 0;
foreach my $line(@lines) # loop thru list
 {
    if ($line eq $oldline)
        {
          $count++;
        }  
        else 
        { 
          if ($count >= $min) {print "$oldline\t$count\n";}
#          print "$count\n";
          $count=1;
          $oldline=$line;
        }
 }

exit;	

