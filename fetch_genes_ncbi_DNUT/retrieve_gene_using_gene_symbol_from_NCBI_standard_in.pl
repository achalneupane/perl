#!/usr/bin/perl
use warnings;
use strict;
use LWP::Simple;
use Time::HiRes qw(usleep nanosleep);

# 1 millisecond == 1000 microseconds
#usleep(100000);
# #1 microsecond == 1000 nanoseconds
#nanosleep(1000000);

#usage: perl file.pl gene_symbol_line_separated.txt
open (my $OUT, '>', 'fetched_genes_seqs_from_NCBI.fa') || die "Can't open file:$!";
my $filename = $ARGV[0];
open(INPUT_FILE, $filename);
while (<INPUT_FILE>) {
chomp;
my $name = $_;
# sleep for milliseconds so NCBI won't flag
usleep(1000000);
# Process each line of the file in $currentLine ...
my $db = 'nuccore';
#query terms: https://www.ncbi.nlm.nih.gov/books/NBK49540/
#my $query = "$name+AND+refseq[filter]";
#my $query = "$name+AND+mrna[filter]";
#my $query = "$name";
my $query = "$name+AND+mrna[filter]";
print "Doing : $query\n";
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
#print "My Key: $key\n";
$url = $base . "esummary.fcgi?db=$db&query_key=$key&WebEnv=$web";

#Run the search using the esummary URL created above
my $docsums = get($url);

$url = $base . "efetch.fcgi?db=$db&query_key=$key&WebEnv=$web";
$url.= "&rettype=fasta&retmode=text";
#Run the search using the efetch URL created above.
my $data = get($url);
print $OUT "$data";
#print "My URL: $url\n";
}
close(INPUT_FILE);

# close $OUT;
# exit;
