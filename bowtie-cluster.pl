#!/usr/bin/perl -w
my $sread = "ACGT-read";
my $strand ="-";
my $rname = "bill";
my $position = 1;
my $sequence = "ACGT";
my $quality = "good";
my $d2 = "d2";
my $d3 = "d3";
my $positive = 0;
my $negative = 0;
my $width = 75;
my $count = 0;
my $seqlen = 0;
my $class1 = 22;
my $class2 = 27;
my $rpm = 1;
my $min = 0;

open (INFILE, "<$ARGV[0]") || die "couldn't open the 1 infile!";
open (OUTFILE, ">$ARGV[1]") || die "couldn't open the 1 outfile!";

while ($rln = <INFILE>){
	chomp $rln;
	($sread, $strand, $rname, $position, $sequence, $quality, $d2,$d3) = split("\t",$rln);
    $seqlen = length ($sequence);
    $d2 = $rname . "#" . sprintf("%010d", $position)  . "#" . sprintf("%06d", 0) . "#" . $seqlen . "#" . $strand;
#    print"$d2\n";
    push (@lines, $d2);
	$count++;
}

close (INFILE);

$min = $count / ($rpm * 1000000);

print "$count,  $min\n";

@lines = sort(@lines); # sort the list

my $size = @lines;

my $clust = 0;
my $ccount = 0;
my $pname = "name";
my $scaff = "name";
my $ppos = 0;
my $pclust = 0;
my $pseqlen = 0;
my $pstrand = "-";
my @clusters;
my $maxd = 0;
my $pcnt_pos = 0;

$clusters[0][0] = 1;
($rname, $pos, $clust, $seqlen, $strand) = split("#",$lines[0]);
$clusters[0][1] = $pos;
$clusters[0][2] = 0;
$clusters[0][3] = $rname;
$clusters[0][4] = 0;
$clusters[0][5] = 0;
$clusters[0][6] = 0;
$clusters[0][7] = 0;

if ($seqlen eq $class1) { $clusters[0][4]++; }
else { if ($seqlen eq $class2) { $clusters[0][4]++; }
   else { $clusters[0][5]++; }
}
 
for (my $i=1; $i <= $size; $i++) {
   ($pname, $ppos, $pclust, $pseqlen, $pstrand) = split("#",$lines[$i-1]);
#   print "$pscaff, $ppos, $pclust\n";
   $maxd = $ppos + $pseqlen + $width;
   ($rname, $position, $clust, $seqlen, $strand) = split("#",$lines[$i]);
   if (($position <= $maxd) && ($pname eq $rname)) {
      $clusters[$ccount][0]++;
      $lines[$i] = $rname . "#" . $position . "#" . sprintf("%06d", $ccount) . "#" . $seqlen . "#" . $strand;
      if ($seqlen eq $class1) { $clusters[$ccount][4]++; }
      else { if ($seqlen eq $class2) { $clusters[$ccount][5]++; }
             else { $clusters[$ccount][6]++; }
      }
      if ($strand eq "+"){ $clusters[$ccount][7]++; }
   }
   else {
      $clusters[$ccount][2] = $ppos + $pseqlen;
      $frac_pos = $clusters[$ccount][7] / $clusters[$ccount][0];
      if ($clusters[$ccount][0] > $min) {
         print "$ccount\t$clusters[$ccount][3]\t$clusters[$ccount][0]\t$clusters[$ccount][1]\t$clusters[$ccount][2]\t$clusters[$ccount][4]\t$clusters[$ccount][5]\t$clusters[$ccount][6]\t$frac_pos\n";
      }
      $ccount++;
      $clusters[$ccount][0] = 1;
      $clusters[$ccount][1] = $position;
      $clusters[$ccount][3] = $rname;
      $clusters[$ccount][4] = 0;
      $clusters[$ccount][5] = 0;
      $clusters[$ccount][6] = 0;
      $clusters[$ccount][7] = 0;
      if ($seqlen eq $class1) { $clusters[$ccount][4]++; }
      else { if ($seqlen eq $class2) { $clusters[$ccount][5]++; }
             else { $clusters[$ccount][6]++; }
      }
      $lines[$i] = $rname . "#" . $position . "#" . sprintf("%06d", $ccount) . "#" . $seqlen . "#" . $strand;
      if ($strand eq "+"){ $clusters[$ccount][7]++; }
   }
}

if ($clusters[$ccount][0] > $min) {
   print "$ccount\t$clusters[$ccount][3]\t$clusters[$ccount][0]\t$clusters[$ccount][1]\t$clusters[$ccount][2]\t$clusters[$ccount][4]\t$clusters[$ccount][5]\t$clusters[$ccount][6]\t$frac_pos\n";
}


close (OUTFILE);
exit;	
