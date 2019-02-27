#!/usr/bin/perl -w

my $fasta_file=$ARGV[0];

$tig = "ACGT";
my @contigs = ();

open (INFILE, "<$ARGV[1]") || die "couldn't open contig list file!";
   (@contigs) = <INFILE>; # read file into list
close (INFILE);

foreach $tig(@contigs) {
   chomp $tig; # remove returns at end of each line
}

my $arrSize = @contigs;
my $fh;
open($fh, $fasta_file) or die "can't open $fasta_file: $!\n";

my %sequence_data;
while (read_fasta_sequence($fh, \%sequence_data)) {
    for (my $i=0; $i<$arrSize; $i++){
       if (index($sequence_data{header}, $contigs[$i]) != -1) {
          print ">$sequence_data{header}\n$sequence_data{seq}\n";
       }
    }
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

exit;
