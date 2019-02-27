##############################################################
###    STAT 736 - Perl Program  (TASK 1) Brandon Monier    ###
##############################################################



### MAIN MENU SUB-ROUTINES ###

main_menu:
system("clear");								# clears command line for "cleaner" look
print "\n+----------------------+\n";		# main menu "graphical" layout
print "| SeqData Program v1.8 |\n";
print "|                      |\n";
print "|      created by      |\n";
print "|    Brandon Monier    |\n";
print "+----------------------+\n\n";
print "MAIN MENU\n";
print "-------------------------------\n";
print "Complementation             [1]\n\n";
print "Reverse Complementation     [2]\n\n";
print "Base Pair Counter           [3]\n\n";
print "GC Content Calculator       [4]\n\n";
print "Molecular Weight Calculator [5]\n\n";
print "EXIT PROGRAM                [6]\n";
print "-------------------------------\n\n";
print "\nPlease enter a numerical choice (1-6): ";

$option = <>;								# allows for manually entering variables														

if ($option == 1){							# sub-routine options	
	&complement								# go to complementation sub-routine
}
elsif ($option == 2){
	&revcomplement;							# go to reverse complementation sub-routine
}
elsif ($option == 3){
	&basepair_counter;						# go to base pair counter sub-routine
}
elsif ($option == 4){
	&gc_content;							# go to gc content calculator sub-routine
}
elsif ($option == 5){
	&mol_weight;							# go to molecular weight calculator sub-routine
}
elsif ($option == 6){
	system("clear");
	exit;									# exits script and clears cache
}
else{
	print "\nIncorrect numerical entry. Press ENTER and try again.";
	<>;
	goto main_menu;							# loops back to main menu if not a numerical entity stated above
}



### FILE DATA RETRIEVAL SUB-ROUTINES ###

sub get_file_data{							# Obtain file data (.txt, .fasta, .fastq, etc.)												
	my($filename) = @_;
	use strict;
	use warnings;
	my @filedata = (  );
	unless( open(GET_FILE_DATA, $filename) ){
		print STDERR "Cannot open file \"$filename\"";
		exit;
	}
	@filedata = <GET_FILE_DATA>;
	close GET_FILE_DATA;
	return @filedata;
}



### SEQUENCE EXTRACTION FROM .FASTA FILE SUB-ROUTINE ###

sub extract_sequence_from_fasta_data {		# begin string conversion from .fasta file
    my(@fasta_file_data) = @_;
    use strict;
    use warnings;
	my $sequence = '';						# initialize variables
	foreach my $line (@fasta_file_data) {
		if ($line =~ /^\s*$/) {				# remove if blank line
            next;
		} elsif($line =~ /^\s*#/) {			# remove if comment line
            next;
		} elsif($line =~ /^>/) {			# remove if fasta header line
            next;
        } else {							# retain everything else and convert to string
            $sequence .= $line;
        }
    }
    $sequence =~ s/\s//g;		 			# remove additional white space
    return $sequence;
}



### PRINT SEQUENCE SUB-ROUTINE ###

sub print_sequence {														# Print the derived sequence data 
	my($sequence, $length) = @_;
	use strict;
	use warnings;
	for ( my $pos = 0 ; $pos < length($sequence) ; $pos += $length ){		# Print sequence in lines of $length
		print substr($sequence, $pos, $length), "\n";
	}
}
my @file_data = (  );														# Declare and initialize variables
my $dna = '';



### COMPLEMENTATION SUB-ROUTINE ###

sub complement(){
	system("clear");
	print "\n+-------------------------------+\n";
	print "|        COMPLEMENTATION        |\n";
	print "+-------------------------------+\n\n";
	print "What would you like to do?\n\n";
	print " Manually enter or paste a sequence   [1]\n\n";
	print " Analyze sequence data from a file    [2]\n\n\n";
	print "Please enter a numerical entry (1 or 2): ";

	$sub_option = <>;																					# manually enter variables 1 or 2
	if ($sub_option == 1){
		print "\n\n\nPlease enter or paste your sequence of interest:\n\n";
		$dna =			<>;					# manually enter sequence
		$dna =~			tr/ATCGatcg/TAGCtagc/;
	}
	elsif ($sub_option == 2){
	print "\n\n\nPlease enter the name of your file including the extension:\n\n";
	$option_seq = 	<>;
	@file_data = 	get_file_data($option_seq) or die "\nERROR: No such file in this directory."; 		# use sub-routine from previous sections
	$dna = 			extract_sequence_from_fasta_data(@file_data);										# use sub-routine from previous sections
	$dna =~ 		tr/ATCGatcg/TAGCtagc/;																# exchange variables using the translate function
	}
	else{
		print "\n\n\nIncorrect numerical entry. Press ENTER and try again.";
		<>;
		goto &complement;																				# loops back to the beginning of the &complement sub-routine
	}

	print "\n\n\nThe complement of your DNA sequence is as follows:\n$dna";								# print-out options for new sequence
	print "\n\n\n\nWould you like to print the output of this data?\n\n";
	print " YES  [1]\n\n";
	print " NO   [2]\n\n\n";
	print "Please enter a numerical entry (1 or 2): ";
	
	$sub_option = <>;
	if ($sub_option == 1){
		print "\n\n\nEnter the name of the output file including the extension:\n\n";					# open a filehandle to the output file
		$output_file_name = <>;																			# manually enter file name and extension
		open OUTPUT, ">$output_file_name";
		print OUTPUT $dna;
		print "\n\n\nAn output file has been created. Press ENTER to return to the main menu. Have a nice day.";
		<>;
		goto main_menu;
	}

	elsif ($sub_option == 2){
	print "\n\n\nPress ENTER to return to the main menu. Have a nice day.";								# returns to main menu sub-routines
	<>;
	goto main_menu;
	}

	else{
		print "\n\n\nIncorrect numerical entry. Press ENTER and try again.";
		<>;
		goto &complement;
	}
}



### REVERSE COMPLEMENTATION SUB-ROUTINE ###

sub revcomplement(){
	system("clear");
	print "\n+-------------------------------+\n";
	print "|    REVERSE COMPLEMENTATION    |\n";
	print "+-------------------------------+\n\n";
	print "What would you like to do?\n\n";
	print " Manually enter or paste a sequence   [1]\n\n";
	print " Analyze sequence data from a file    [2]\n\n\n";
	print "Please enter a numerical entry (1 or 2): ";

	$sub_option = <>;																	# manually enter variables 1 or 2
	if ($sub_option == 1){
	print "\n\n\nPlease enter or paste your sequence of interest:\n\n";
		$dna =			<>;																# manually enter sequence
		$dna =~			tr/ATCGatcg/TAGCtagc/;											# complement function
		$dna =			reverse($dna);													# reverses the string of characters after complementation is complete
	}
	elsif ($sub_option == 2){
		print "\n\n\nPlease enter the name of your file including the extension:\n\n";
		$option_seq = 	<>;		# manually enter the file name and extension
		@file_data = 	get_file_data($option_seq) or die "\nERROR: No such file in this directory.";
		$dna = 			extract_sequence_from_fasta_data(@file_data);
		$dna =~ 		tr/ATCGatcg/TAGCtagc/;
		$dna = 			reverse($dna);
	}
	else{
		print "\n\n\nIncorrect numerical entry. Press ENTER and try again.";
		<>;
		goto &revcomplement;															# loops back to the beginning of &revcomplement sub-routine
	}

	print "\n\n\nThe reverse complement of your DNA sequence is as follows:\n$dna";		# output field
	print "\n\n\n\nWould you like to print the output of this data?\n\n";				# more user options
	print " YES  [1]\n\n";
	print " NO   [2]\n\n\n";
	print "Please enter a numerical entry (1 or 2): ";

	$sub_option = <>;
	if ($sub_option == 1){
		print "\n\n\nEnter the name of the output file including the extension:\n\n";	# open a filehandle to the output file
		$output_file_name = <>;															# manually enter the file name and extension for saving
		open OUTPUT, ">$output_file_name";												# writes file to directory where script is located unless noted otherwise
		print OUTPUT $dna;
		print "\n\n\nAn output file has been created. Press ENTER to return to the main menu. Have a nice day.";
		<>;
		goto main_menu;
	}

	elsif ($sub_option == 2){
		print "\n\n\nPress ENTER to return to the main menu. Have a nice day.";			# returns to the main menu sub-routine at the begiinning of the script
		<>;
		goto main_menu;
	}

	else{
		print "\n\n\nIncorrect numerical entry. Press ENTER and try again.";			# loops back to the beginning of the &revcomplement sub-routine
		<>;
		goto &revcomplement;
	}
}



### BASE PAIR COUNTER SUB-ROUTINE ###

sub basepair_counter(){
	system("clear");
	print "\n+-------------------------------+\n";
	print "|       BASE PAIR COUNTER       |\n";
	print "+-------------------------------+\n\n";
	print "What would you like to do?\n\n";
	print " Manually enter or paste a sequence   [1]\n\n";
	print " Analyze sequence data from a file    [2]\n\n\n";
	print "Please enter a numerical entry (1 or 2): ";
	
	$sub_option = <>;
	if ($sub_option == 1){
		print "\n\n\nPlease enter or paste your sequence of interest:\n\n";
		$dna =			<>;
		$a = 			($dna =~ tr/Aa//);											# counts the number of A's in string
		$t = 			($dna =~ tr/Tt//);											# counts the number of T's in string
		$c = 			($dna =~ tr/Cc//);											# counts the number of C's in string
		$g = 			($dna =~ tr/Gg//);											# counts the number of G's in string
		$total = 		$a + $t + $c + $g;											# counts the total number of characters in string
		$perc_a = 		($a/$total)*100;											# calculate the % of A's
		$perc_t = 		($t/$total)*100;											# calculate the % of T's
		$perc_c = 		($c/$total)*100;											# calculate the % of C's
		$perc_g = 		($g/$total)*100;											# calculate the % of G's
		$perc_total =	($perc_a + $perc_t + $perc_c + $perc_g); 					# total percentage
	}
	elsif ($sub_option == 2){
		print "\n\n\nPlease enter the name of your file including the extension:\n\n";
		$option_seq = 	<>;
		@file_data = 	get_file_data($option_seq) or die "\nERROR: No such file in this directory.";
		$dna = 			extract_sequence_from_fasta_data(@file_data);
		$a = 			($dna =~ tr/Aa//);											# same as previous entries
		$t = 			($dna =~ tr/Tt//);
		$c = 			($dna =~ tr/Cc//);
		$g = 			($dna =~ tr/Gg//);
		$total = 		$a + $t + $c + $g;
		$perc_a = 		($a/$total)*100;
		$perc_t = 		($t/$total)*100;
		$perc_c = 		($c/$total)*100;
		$perc_g = 		($g/$total)*100;
		$perc_total =	($perc_a + $perc_t + $perc_c + $perc_g);
	}
	else{
		print "\n\n\nIncorrect numerical entry. Press ENTER and try again.";
		<>;
		goto &basepair_counter;
	}
	print "\n\n\nThis DNA sequence contains the following:\n\n\n";					# overly complicated output to showcase percentages of 
																					# characters in a string along with raw counts
	print "BASE PAIR		COUNT		[%]\n";
	print "-----------------------------------------------\n";
	print "A (Adenine)		$a		";printf("%.3f", $perc_a);print "\n\n";			# calculates percentage outputs to 3 floating decimal values in case of complex number
	print "T (Thymine)		$t		";printf("%.3f", $perc_t);print "\n\n";
	print "C (Cytosine)		$c		";printf("%.3f", $perc_c);print "\n\n";
	print "G (Guanine)		$g		";printf("%.3f", $perc_g);print "\n";
	print "-----------------------------------------------\n";
	print "OVERALL LENGTH		$total		";printf("%.3f", $perc_total);print "\n";
	print "\n\n\nPress ENTER to return to the main menu. Have a nice day.";
	<>;
	goto main_menu;
}



### GC CONTENT CALCULATOR SUB-ROUTINE ###

sub gc_content(){
	system("clear");
	print "\n+-------------------------------+\n";
	print "|     GC CONTENT CALCULATOR     |\n";
	print "+-------------------------------+\n\n";
	print "What would you like to do?\n\n";
	print " Manually enter or paste a sequence   [1]\n\n";
	print " Analyze sequence data from a file    [2]\n\n\n";
	print "Please enter a numerical entry (1 or 2): ";
	
	$sub_option = <>;
	if ($sub_option == 1){
		print "\n\n\nPlease enter or paste your sequence of interest:\n\n";
		$dna =			<>;
		$a = 			($dna =~ tr/Aa//);											# same as previous entries
		$t = 			($dna =~ tr/Tt//);
		$c = 			($dna =~ tr/Cc//);
		$g = 			($dna =~ tr/Gg//);
		$gc = 			($g + $c)/($a + $t + $g + $c)*100;							# formula to determine the GC content of a DNA string
	}
	elsif ($sub_option == 2){
		print "\n\n\nPlease enter the name of your file including the extension:\n\n";
		$option_seq = 	<>;
		@file_data = 	get_file_data($option_seq) or die "\nERROR: No such file in this directory.";
		$dna = 			extract_sequence_from_fasta_data(@file_data);
		$a = 			($dna =~ tr/Aa//);
		$t = 			($dna =~ tr/Tt//);
		$c = 			($dna =~ tr/Cc//);
		$g = 			($dna =~ tr/Gg//);
		$gc =			($g + $c)/($a + $t + $g + $c)*100;
	}
	else{
		print "\n\n\nIncorrect numerical entry. Press ENTER and try again.";
		<>;
		goto &basepair_counter;														# if wrong value entered, loops back to beginning of sub-routine
	}
	print "\n\nGC-content:  "; printf("%.3f", $gc); print "%";
	print "\n\n\nPress ENTER to return to the main menu. Have a nice day.";
	<>;
	goto main_menu;
}



### MOLECULAR WEIGHT CALCULATOR SUB-ROUTINE ###

sub mol_weight(){
	system("clear");
	
	print "\n+-------------------------------+\n";
	print "|  MOLECULAR WEIGHT CALCULATOR  |\n";
	print "+-------------------------------+\n\n";
	print "What would you like to do?\n\n";
	print " Manually enter or paste a sequence   [1]\n\n";
	print " Analyze sequence data from a file    [2]\n\n\n";
	print "Please enter a numerical entry (1 or 2): ";
	
	
	$sub_option = 		<>;
	if ($sub_option == 1){
		print "\n\n\nPlease enter or paste your sequence of interest:\n\n";
		$dna =			<>;
		$a = 			($dna =~ tr/Aa//);											# similar to the previous two sections
		$t = 			($dna =~ tr/Tt//);
		$c = 			($dna =~ tr/Cc//);
		$g = 			($dna =~ tr/Gg//);
		$molwt = 		($a*313.2) + ($t*304.2) + ($c*289.2) + ($g*329.2) + 79.0; 	# formula for determining the molecular weight which was derived from
																					# http://www.basic.northwestern.edu/biotools/oligocalc.html
	}
	elsif ($sub_option == 2){
		print "\n\n\nPlease enter the name of your file including the extension:\n\n";
		$option_seq = 	<>;
		@file_data = 	get_file_data($option_seq) or die "\nERROR: No such file in this directory.";
		$dna = 			extract_sequence_from_fasta_data(@file_data);
		$a = 			($dna =~ tr/Aa//);											# same as previous sections
		$t = 			($dna =~ tr/Tt//);
		$c = 			($dna =~ tr/Cc//);
		$g = 			($dna =~ tr/Gg//);
		$molwt = 		($a*313.2) + ($t*304.2) + ($c*289.2) + ($g*329.2) + 79.0;	# see previous section for further details
	}
	else{
		print "\n\n\nIncorrect numerical entry. Press ENTER and try again.";
		<>;	
		goto &basepair_counter;
	}
	
	print "\n\nMolecular Weight:  "; printf("%.3f", $molwt); print " g/mol";		# prints decimal values to 3 floating integers
	print "\n\n\nPress ENTER to return to the main menu. Have a nice day.";
	
	<>;
	goto main_menu;																	# loops back to the main menu when script is complete
}