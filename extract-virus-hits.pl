#!/usr/bin/perl -w

use List::MoreUtils qw(firstidx);

my $in_file=$ARGV[0];
my $fasta_file=$ARGV[1];
my $file_tag=$ARGV[2];
my $out_file=$ARGV[3];
my $out_fasta=$ARGV[4];

my ($CNAME, $K1, $K2, $L1, $L2) = ('','','','','');

my $tig = "ACGT";
my @contigs = ();
my @namess = ();
my $virus = "bill";

my $query = "gene";
my $oldquery = "bob";
my $subject = "seq";
my ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
my $substr = "virus";

$ctn = 0;

open (INFILE, "<$in_file") || die "couldn't open input file!";
while ($rln = <INFILE>) {
   chomp ($rln);
   ($query, $subject, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10) = split("\t",$rln);
   if ($query ne $oldquery) {
      if ($subject =~ /$substr/) {
         ($CNAME, $K1, $K2, $L1, $L2) = split(" ",$query);
         push (@names, $CNAME);
         push (@contigs, $rln);
         $ctn ++;
      }
   } 
   $oldquery = $query;
}
print "$ctn\n";

close (INFILE);

$ctn = 0;

my $arrSize = @contigs;

my $fh;
open($fh, $fasta_file) or die "can't open $fasta_file: $!\n";
open (FASTAFILE, ">$out_fasta") || die "couldn't open output fasta file! $out_fasta";
open (TABFILE, ">$out_file") || die "couldn't open output file! $out_file";

print TABFILE "Sample\tQuery\tVirus\tProtein\tPcntID\tAlnLen\tNumMis\tNumGap\tQStart\tQEnd\tTStart\tTEnd\tE-value\tBitScr\tLen\tSequence\n";

my %sequence_data;
while (read_fasta_sequence($fh, \%sequence_data)) {
   ($CNAME, $K1, $K2, $L1, $L2) = split(" ",$sequence_data{header});
   $i = firstidx { $_ eq $CNAME } @names;
   if ($i > -1) {
       ($query, $subject, $d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $d9, $d10) = split("\t",$contigs[$i]);
       ($K1, $virus) = split("=",$subject);
       $seqLen = length ($sequence_data{seq});
       print "writing sequence $i of $arrSize $virus\n";
       print TABFILE "$file_tag\t$query\t$virus\t$K1\t$d1\t$d2\t$d3\t$d4\t$d5\t$d6\t$d7\t$d8\t$d9\t$d10\t$seqLen\t$sequence_data{seq}\n";
       print FASTAFILE ">${CNAME}_${file_tag}\n$sequence_data{seq}\n\n";
   }
}

close (FASTAFILE);
close (TABFILE);
close ($fh);


sub read_fasta_sequence {
   my ($fh, $seq_info) = @_;

   $seq_info->{seq} = undef; # clear out previous sequence

   # put the header into place
   $seq_info->{header} = $seq_info->{next_header} if $seq_info->{next_header};

   my $file_not_empty = 0; 
   while (<$fh>) {
      $file_not_empty = 1;
      next if /^\s*$/;  # skip blank lines
      chomp;    

      if (/^>/) { # fasta header line
         my $h = $_;    
         $h =~ s/^>//;  
         if ($seq_info->{header}) {
            $seq_info->{next_header} = $h;
            return $seq_info;   
         }              
         else { # first time through only
            $seq_info->{header} = $h;
         }              
      }         
      else {    
         s/\s+//;  # remove any white space
         $seq_info->{seq} .= $_;
      }         
   }    

   if ($file_not_empty) {
      return $seq_info;
   }    
   else {
      # clean everything up
      $seq_info->{header} = $seq_info->{seq} = $seq_info->{next_header} = undef;

      return;   
   }    
}

exit;
