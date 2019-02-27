#!/usr/bin/perl -w
##use this to count the file from the cluster
#usage infile outfile min_length max_length min_count
#eg; /count-seq.pl Ss-deg-reads.fasta Ss-deg-reads-counted.txt 18 27 1
#here 1 indicates the minimum of 1 read in the cluster

my $min_len = $ARGV[2];
my $max_len = $ARGV[3];
my $min_count = $ARGV[4];
my $read_len = 0;
my $seq_num = 0;


my $count = 0;

my @lines;
my $temp = "head";;
my $oldline = "rwd";

open (INFILE, "<$ARGV[0]") || die "couldn't open input file!";

   $count = 0;
   while (<INFILE>) {
      $temp = $_;
      chomp($temp);
      $count++;
      if ($count == 2){
        push (@lines, $temp);
      }   
      else {
         if ($count == 4){
            $count = 0;
         }
      }
   }
close (INFILE);

@lines = sort(@lines); # sort the list

$count = 0;

open (OUTFILE, ">$ARGV[1]") || die "couldn't open output file!";

my $total = 1;

foreach my $line(@lines) # loop thru list
 {
    if ($line eq $oldline)
        {
          $count++;
        }  
        else 
        { 
          if ($count >= $min_count) {
             $read_len = length ($oldline);
             $seq_num ++;
             if (($read_len >= $min_len) and ($read_len <= $max_len)){
                print OUTFILE ">Seq_${seq_num}_$count\n$oldline\n";
                $total ++;  
             }
          }
          $count=1;
          $oldline=$line;
        }
 }
close (OUTFILE);
exit;
