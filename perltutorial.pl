#!/usr/bin/perl
# @ranks=(1..10);
# @alphabets=(a..z);
# print "All ranks: @ranks\n";
# $si=@ranks;
# print "All ranks size: $si\n";

# push(@alphabets,"new_alphabet");
# print "All alphabets: @alphabets\n";

# pop(@alphabets);
# print "All alphabets: @alphabets\n";

# shift(@alphabets);
# print "All alphabets after shift: @alphabets\n";

# unshift(@alphabets, "new_unshifted  alphabet");
# print "All unshifted alphabets: @alphabets\n";

# @months= ('Jan'..4);
# print "The dates are: @months\n";

# $x=10;
# while ($x<=2000) {
# 	print "The value of X: $x\n";
# 	$x=$x+1
# }

# $x=10;
# until($x>20){
# 	print "The value of x is $x\n";
# 	$x=$x+1;
# }



# for($x=10; $x<=20; $x++){
# 	print "the value of x $x\n";
# }


# for($x=10; $x<=20; $x=$x+1){
# 	print "the value of x $x\n";
# }



# @tennis=('novak','roger','andy','kei','berdych','rafa');
# print "The top players are-:\n";

# foreach $va (@tennis){
# 	print "the value var is $va\n";
# }


# $x=100;


# do

# {
# 	print "the value of x: $x\n";
# 	$x=$x+1;
# }while ($x<20);




# $x=90;
# $y=75;
# printf "x is : %b\n", $x;
# printf "y is : %b\n", $y;

# $and_op=$x&$y;
# printf "Result of BITWISE AND: %b\n", $and_op;

# $or_op=$x|$y;
# printf "Result of BITWISE OR: %b\n", $or_op;

# $xor_op=$x^$y;
# printf "Result of BITWISE XOR: %b\n", $xor_op;

# $comp=(~$x);
# printf "1's compliment of x is: %b\n", $comp;


# #sprintf is a formatter and doesn't do any printing at all:
# $result = sprintf('The %s is %d', 'answer', 42);
# print "the result of sprintf is : $result\n";
$number=233443.8889993388;
# my $result = sprintf("%02d", $number);
# print "the result of sprintf is : $result\n";
my $rounded = sprintf("%.3f", $number);
print "the result of sprintf is : $rounded\n";
#printf is the same as sprintf, but actually prints the result:
# printf 'This is question %d on %s', 36882022, 'StackOverflow';



