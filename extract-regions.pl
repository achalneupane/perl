#!/usr/bin/perl -w

my $fasta_file=$ARGV[0];
my $header = " ";

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
   foreach my $tig (@contigs) {
      ($name, $start, $frag_len) = split("\t",$tig);
#      print "$sequence_data{header}     $name\n";
      if ($name eq $sequence_data{header}) {
         my $fragment =  substr ($sequence_data{seq}, $start, $frag_len);
         print ">$name\_$start\_$frag_len\n$fragment\n";
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
