#!/usr/bin/perl
use strict;
use warnings;
use diagnostics; 

#usage ./count-smRNAs.pl infile min_length max_length

my $min_len = $ARGV[1];
my $max_len = $ARGV[2];
my $read_len = 0;
my @lines = ("header1","sequence","header2","quality");
my @lray = ();
my $count = 0;
my $total = 0;
my $i = 0;

my @Aray = ();
my @Cray = ();
my @Gray = ();
my @Tray = ();

my$FN = "";

for ($i=$min_len; $i<=$max_len; $i++){
   $lray[$i] = 0;
}

open (INFILE, "<$ARGV[0]") || die "couldn't open input file!";
   while (<INFILE>) {
      $lines[$count] = $_;
      chomp($lines[$count]);
      $count++;
      if($count eq 4){
         $read_len = length($lines[1]); 
#         print "$read_len $lines[1]\n";
         $FN = substr $lines[1], 0, 1;  
         $lray[$read_len]++;
         if ($FN eq "T") { $Tray[$read_len]++;} 
         else {        
            if ($FN eq "A"){ $Aray[$read_len]++;}
            else {
               if ($FN eq "C"){ $Cray[$read_len]++;}
               else {
                 if ($FN eq "G"){ $Gray[$read_len]++;}
               }   
            }
         }           
         $count = 0;
      }
   }
print "length\tnumber\tA\tC\tG\tT\n";
for ($i=$min_len; $i<=$max_len; $i++){
   print "$i\t$lray[$i]\t$Aray[$i]\t$Cray[$i]\t$Gray[$i]\t$Tray[$i]\n";
}
exit;
