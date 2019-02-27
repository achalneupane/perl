#!/usr/bin/perl
#use strict;
#use warnings;
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
    $mray[$i][4]=0;
    $mray[$i][5]=0;
    $mray[$i][6]=0;
    $mray[$i][7]=0;
    $mray[$i][8]=0;
    $mray[$i][9]=0;
    $mray[$i][10]=0;
    $mray[$i][11]=0;
}

open (INFILE, "<$ARGV[0]") || die "couldn't open the 1 infile!";

while ($rln = <INFILE>){
	chomp $rln;
	($sread, $strand, $name, $position, $sequence, $quality, $d2,$d3) = split("\t",$rln);
#	print "what is d3 \n $d3\n";
    $seq_len = length ($sequence);
    if ($seq_len == $class && $d3){
#	print "what is d3 \n $d3\n";
       ($position, $d2) = split(":",$d3);
#	print "what is d2 \n $d2\n";
       $var = substr $d2, -1;
       $var2 = substr $d2, 0;
#	print "what is substring d2 \n (substr $d2)\n";
#	print "what is var \n $var\n";
#	print "what is var2 \n $var2\n";
#	print "what is class \n $class\n";
#	print "what is sequence \n $sequence\n";
       if ($var2 eq "A>T" ) { $mray[$position][0]++ }
       if ($var2 eq "A>G" ) { $mray[$position][1]++ }
       if ($var2 eq "A>C" ) { $mray[$position][2]++ }
       if ($var2 eq "C>T" ) { $mray[$position][3]++ }
       if ($var2 eq "C>G" ) { $mray[$position][4]++ }
       if ($var2 eq "C>A" ) { $mray[$position][5]++ }
       if ($var2 eq "G>T" ) { $mray[$position][6]++ }
       if ($var2 eq "G>A" ) { $mray[$position][7]++ }
       if ($var2 eq "G>C" ) { $mray[$position][8]++ }
       if ($var2 eq "T>A" ) { $mray[$position][9]++ }
       if ($var2 eq "T>G" ) { $mray[$position][10]++ }
       if ($var2 eq "T>C" ) { $mray[$position][11]++ }


#	print "what is mray \n $mray[$position][3]\n";
       if ($position == ($class-1)) {
           $read = substr $sequence, 0, $class-1;
           push (@lines, $read);
#	print "what is read \n $read\n";
#	print "what is position \n $position\n";
       }
    }
}
close (INFILE);
print "Pos\tA>T\tA>G\tA>C\tC>T\tC>G\tC>A\tG>T\tG>A\tG>C\tT>A\tT>G\tT>C\n";
for (my $i=0; $i < $class; $i++) {
    $pnum = $i + 1;
    print "$pnum\t$mray[$i][0]\t$mray[$i][1]\t$mray[$i][2]\t$mray[$i][3]\t$mray[$i][4]\t$mray[$i][5]\t$mray[$i][6]\t$mray[$i][7]\t$mray[$i][8]\t$mray[$i][9]\t$mray[$i][10]\t$mray[$i][11]\n";
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

