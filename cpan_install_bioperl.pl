#!/usr/bin/perl

use strict;
use warnings;
use CPAN;

CPAN::Shell->install(

"Bundle::BioPerl",
"Bio::Seq",
"Bio::SeqIO::staden::read",
"Bio::Factory::EMBOSS",
"Bio::Tk::SeqCanvas",
"Bio::DB::Annotation");
