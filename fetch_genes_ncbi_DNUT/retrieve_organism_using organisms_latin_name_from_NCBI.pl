#!/usr/bin/perl
use warnings;
use strict;
use LWP::Simple;

##can fetch genes matching organisms from NCBI
##reference: ###Ref:https://www.biostars.org/p/52852/

open (my $OUT, '>', '/media/owner/7ef86942-96a5-48a7-a325-6c5e1aec7408/symarzano2018June.201875/2018June.201875.bz2_files/trimmed_files/bbmap_trimmed_slagem_name_swapped_with_WTDK3/SsGenome/fastq.out/fastq.out_zero_mismatch_allowed/differential_expression/fasta_sshv2l_vs_VF/test_organism_seqs.fa') || die "Can't open file:$!";

open(INFILE,"</Users/owner1/Dropbox/perl/org.txt>){
    chomp;
    my $name = $_;
    $name.="[ORGN]";

my $db = 'nuccore';
my $query = "$name+AND+srcdb_refseq[PROP]";

#base URL
my $base = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/';
my $url= $base . "esearch.fcgi?db=$db&term=$query&usehistory=y";

#Run the search using the URL created above
my $output = get($url);

#Web Environment. This parameter specifies the Web Environment that 
#contains the UID list to be provided as input to ESummary. Usually 
#this WebEnv value is obtained from the output of a previous ESearch, 
#EPost or ELink call. The WebEnv parameter must be used in 
#conjunction with query_key.
my $web = $1 if ($output =~ /<WebEnv>(\S+)<\/WebEnv>/);

#Query key. This integer specifies which of the UID lists attached to the given 
#Web Environment will be used as input to ESummary.  Query keys are obtained
# from the output of previous ESearch, EPost or ELink calls.  The query_key 
#parameter must be used in conjunction with WebEnv.
my $key = $1 if ($output =~ /<QueryKey>(\d+)<\/QueryKey>/);

$url = $base . "esummary.fcgi?db=$db&query_key=$key&WebEnv=$web";

#Run the search using the esummary URL created above
my $docsums = get($url);

$url = $base . "efetch.fcgi?db=$db&query_key=$key&WebEnv=$web";
$url.= "&rettype=fasta&retmode=text";

#Run the search using the efetch URL created above.
my $data = get($url);
print $OUT "$data";
}

close $OUT;
exit;
