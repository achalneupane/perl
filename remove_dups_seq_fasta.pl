##This perl script removes duplicate sequences from fast file
#!/usr/bin/perl
use strict;
use Bio::SeqIO;
my %unique;

##Usage: perl remove_dups_seq_fasta.pl input_fasta_with_duplicate_sequences.fasta

#my $file   = "/media/owner/newdrive/phasing/small_RNA/test.fasta";
my $file = $ARGV[0];
my $seqio  = Bio::SeqIO->new(-file => $file, -format => "fasta");
my $outseq = Bio::SeqIO->new(-file => ">$file.uniq", -format => "fasta");

while(my $seqs = $seqio->next_seq) {
  my $id  = $seqs->display_id;
  my $seq = $seqs->seq;
  unless(exists($unique{$seq})) {
    $outseq->write_seq($seqs);
    $unique{$seq} +=1;
  }
}
