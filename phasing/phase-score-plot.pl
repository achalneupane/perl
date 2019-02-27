#!/usr/bin/perl -w

#usage ./phase-score.pl bowtie_file fasta_file width min_count >outfile.csv 

#Second, a phase score, P, was calculated using the following formula:
#equation M1
#
#n = number of phase cycle positions occupied by at least one small RNA read within an eight-cycle window
#k = the total number of reads for all small RNAs with consolidated start coordinates in a given phase within an eight-cycle window. Phase cycle length was set at 21 nucleotides. A positive phase signal, therefore, was limited by the power function (n − 2) to those loci with small RNAs occupying at least three cycle positions in a phased, 21-nucleotide register
#. Requiring occupation of three positions in an eight-cycle window limited the possibility of a 
#positive phase score by chance. 
#my $cycles = 8;


#$seq_len = length($seq)

#$end_scan = $cycles*phase_length

#for (my $i = 0, $i++ $i < $cycles) {
#   $all_reads = $all_reads + $k[$i];
#   if sequence[$pos+$i*width] > 0) {
#      $occupied ++;
#   }   
#}

#$phase_score =log((1 + $all_reads)**($occupied -2))

my $sel_len = 22;
my $phase_len = 22;
my $num_cycles = 10;
my $end_sub = $phase_len * $num_cycles - 1;
my $min_loci = 3;
my $min = 3;

my $count = 0;
#my $width = $ARGV[2];
#my $min_count = $ARGV[3];
#my $strt = 0;
#my $stp = $strt + $width;

my $sread = "seq-read";
my $strand = "+";
my $scaff = "chrosome_01";
my $position = "16579";
my $sequence = "ACGT";
my $quality = "VERYGOOD";
my $d2 = "1a67d";
my $mismatch = "25C";

my $rln = " ";
my $oldscaff = "Reference";
my @lines = ();
my $oldline = "rwd";
my $posmm = 0;
my $temp = 0;
my $abundance = 0;
my $seq_rec = "wally";

open (INFILE, "<$ARGV[0]") || die "couldn't open input file!";
while ($rln = <INFILE>) {
  chomp ($rln);
  if (substr ($rln,0,1) ne "#") {
      ($sread, $strand, $scaff, $position, $sequence, $quality, $d2, $mismatch) = split("\t",$rln);
      ($d2, $abundance) = split("x",$sread);
      if ($strand eq "-") {
         $position = $position - 2;
      }
      $read_len = length($sequence);
      $seq_rec = $scaff . "#" . sprintf("%05d", $position) . "#" . $sequence . "#" . $read_len . "#" . $strand . "#" . $abundance;
      push (@lines, $seq_rec);
  }
}
close (INFILE);
@lines = sort(@lines); # sort the list

my $fasta_file = $ARGV[1];
my $fh;
open($fh, $fasta_file) or die "can't open $fasta_file: $!\n";

my @seq_len = ();
my %sequence_data;
my $num_seqs = 0;
my $frag_des = "bill";

while (read_fasta_sequence($fh, \%sequence_data)) {
   $frag_len = length($sequence_data{seq});
   $frag_des = $sequence_data{header} . "#" . $frag_len;
   push (@seq_len, $frag_des);
   $num_seqs++;
}
@seq_len = sort(@seq_len); # sort the list

#foreach $a (@lines){
#    print "value of a: $a\n";
#}

#my $i=0;
#foreach $a (@seq_len){
#    print "$i  value of a: $a\n";
#    $i++;
#}

my @seq_mat = (); 
$i=0;
foreach $a (@seq_len){
   ($scaff, $num) = split("#",$a);
   for (my $j=0; $j < $num; $j++) {
      $seq_mat[$i] [$j] = 0;
#      print "$a  $i $j\n";
    }
    $i++;
}

$i=0;
foreach $a (@seq_len){
   ($scaff, $num) = split("#",$a);
   $j = 0;
   foreach $b (@lines) {
      ($hit_scaff, $position, $sequence, ,$read_len, $strand, $abundance) = split("#",$b);
      if ($hit_scaff eq $scaff && $read_len == $sel_len) {
         $seq_mat[$i][$position] = $seq_mat[$i][$position] + $abundance;
         $num = $seq_mat[$i][$position];
#         print "abundance - $i, $position, $num\n";
      }
      $j++;
    }
    $i++;
}

my @seq_array;
$i=0;
foreach $a (@seq_len){
   ($scaff, $scaf_len) = split("#",$a);
   @seq_array = ();
   for (my $j = 0; $j < $scaf_len;  $j++) {
      push (@seq_array, $seq_mat[$i][$j]);
   }
   my $average = average(@seq_array);
   my $std_dev = std_dev($average, @seq_array);
   my $max = $average = average(@seq_array) + $std_dev ;
   for (my $j = 0; $j < $scaf_len;  $j++) {
      if ($seq_mat[$i][$j] > $max) {
         $seq_mat[$i][$j] = $min +1;
      }
   }
   $i++;
}



$i=0;
foreach $a (@seq_len){
   ($scaff, $scaf_len) = split("#",$a);
   print "$scaff, $scaf_len\n";
   $start_pos = 0;
   $end_pos = $scaf_len - $end_sub;
   while ($start_pos < $end_pos) {
      $cycle_end = $end_sub + $start_pos+1;
      $phased_reads = 0;
      $phased_loci = 0;
      $unphased_reads = 0;
      for (my $j = $start_pos; $j < $cycle_end;  $j++) {
         $remainder = ($j-$start_pos+1) % $phase_len;
         if ($remainder == 0) {
            $phased_reads = $phased_reads +  $seq_mat[$i][$j];
            if ($seq_mat[$i][$j] > 0) {
               $phased_loci ++;
            }
         }
         else {
            $unphased_reads = $unphased_reads + $seq_mat[$i][$j];
         }
      }
      if ($phased_loci >= $min_loci) {
         $phase_score = log ((1 + 10 * $phased_reads / (1+$unphased_reads)) ** ($phased_loci-2))
      }
      else {
         $phase_score = 0;
      } 
      print "$scaff\t$start_pos\t$phase_score\n";
      $start_pos ++;
   }
   $i++;
}


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

sub std_dev {
        my ($average, @values) = @_;

        my $count = scalar @values;
        my $std_dev_sum = 0;
        $std_dev_sum += ($_ - $average) ** 2 for @values;

        return $count ? sqrt($std_dev_sum / $count) : 0;
}

sub average {
        my (@values) = @_;

        my $count = scalar @values;
        my $total = 0; 
        $total += $_ for @values; 

        return $count ? $total / $count : 0;
}


exit;   
