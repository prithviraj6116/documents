#!/usr/bin/perl -l

use strict;
use warnings;
print("$ENV{'env1'}");

my $int1 = 12;#global variable 
my $double1 = 31.1;#block-scoped (local) variable
my $string1 = "first";
my $string2 = 'second';
my @arrayOfInt1 =(11,22,33,44,55,66,77,88);
my @arrayOfString1 =("s1","s2","s3");
my @arrayOfMixed1 =("s1",2,"s3");
my @matrixOfInt1=([1,2,3],[4,5,6]);
my @matrixOfInt2=([{1,"nested1"},2,3],[4,5,6]);

my %hash1 = ("key1","value1","key2","value2");
my %hash2 = ("key1"=>"value11","key2"=>"value22");
my @hash1Values = values(%hash1);
my @hash1Keys = keys(%hash1);

my $refScalar1 = \1;
my $refScalar2 = \"abc";
my $refArray1 = [1,2,3];
my $refHash1 = {"key1"=>"value1",'hash1'=>\%hash2,"key2"=>[22,11]};
my $refToExistingScalar1 = \$int1;
my $refToExistingArray1 = \@arrayOfInt1;
my $refToExistingMatrix1 = \@matrixOfInt1;

my $arrayOfInt1End = $#arrayOfInt1;

my $duckTyping1 = 12 . "3";
my $duckTyping2 = 12 + "3";

my $stringConcat1 = "$string1 and $string2";
my $stringConcat2 = $string1 . " and " . $string2;
my $stringMultiplication1 = $string1 x '3';
my $NumericComparisions1 = 1==1 && 1!=2 && 1<2 && 2>1 && 1<=2 && 1>=1;
my $StringComparison1 =   
'1'eq'1' && '1'ne'2' && '1'lt'2' && '99'gt'100' && '1'le'2' && '1'ge'1';
$int1+=1;
$int1-=1;
$string1.=":s1";
my $init2=1;
exit;

my @array1=(1,2,3);
print(unshift(@array1,4));
print(@array1);

use Math::Trig;
my $tanX = tan(0.9);
print($tanX);


use File::Basename;
use lib dirname (__FILE__);
#use myperlmodule1;
#myperlmodule1::myperlmodule1f1();



#END { print "end1" }
#print "after begin";
#BEGIN { my $init3=1;print "begin1";print "begin2";}

#use feature "switch";
#for($int1) {
#    when (12){print("12");}
#    default{print("default")}
#}

my $regexString1="fooc bar food bar";
print($regexString1);
my $regexString2="foo12bar car43dog bar";
$regexString2=~s/(\D*)(\d*)(\S)/$1 $2 $3/g;
print($regexString2);

sub todo_function1 { ... }
todo_function1();

my $q1=q*whe\*${int1} re*;
my $qq1=qq*whe\*$int1 ree*;
my @qw1=qw(aa bb cc);
my @qw2=qw(11 22 33);
print($q1);
print($qq1);
print(@qw1);
print(@qw2);


open(my $fileReadH1,"<","fileio1.txt");
my $fileline1=<$fileReadH1>;chomp($fileline1);
print($fileline1);
$fileline1=<$fileReadH1>;chomp($fileline1);
print($fileline1);
open($fileReadH1,"<","fileio1.txt");
my @filelines1=<$fileReadH1>;
print("----");
print(@filelines1);
print("----");
open($fileReadH1,"<","fileio1.txt");
while(<$fileReadH1>){
    my $v1=$_;
    chomp($v1);
    print($v1);
}


#while(<>){
#    print("$_");
#}

#types/introspection
#ir
#integer promotion rules
#floating point arithmatic
#assembly
#ssa
#ast
#jit
#templates/generic programming
#bash/csh/sh/tsh
#regex
#string formatting
#class, inheritance, virtual,
#functions
#modules
#i/o
#capi
#namespaces/scopes
#os/kernel api
#matrix ops
#ui
#piping
#interprocess
#thread
#synchronization
#parallel
#optimizations

sub subroutinePassByReference1 {
    my $p1 = \$_[0];
    ${$p1}=32;
    $_[0]=$_[0]+1;
}
print($int1);
subroutinePassByReference1($int1);
print($int1);
my $refInt1=\$int1;
${$refInt1}=54;
print($int1);


print("$ENV{'env1'}");
print("$ENV{'PATH'}");
print($matrixOfInt2[0][0]->{'1'});
print($stringMultiplication1);
print($duckTyping1);
print($duckTyping2);
print($NumericComparisions1);
print($StringComparison1);

my $whileIndex=0;
while($whileIndex<5){
    #print($whileIndex);
    $whileIndex++;
}
until($whileIndex==0){
    #print($whileIndex);
    $whileIndex--;
}

print($refHash1->{'hash1'}->{'key2'});
print($refHash1->{'key2'}->[0]);
print(%{${\$refHash1}});
print(%{${\$refHash1->{"hash1"}}});
print("-------");
print("hash value1: $hash2{'key1'} : @hash1Values : @hash1Keys");
print("ref to scalar: $refScalar1 : ${$refScalar1}");
print("ref to scalar: $refScalar2 : ${$refScalar2}");
print("ref to array1: $refArray1 : @{$refArray1} : @{$refArray1}[0..2]");
print("ref to array2: $refArray1 : @{$refArray1} : $refArray1->[1]");
print("ref to matrix2: $refToExistingMatrix1 : @{@{$refToExistingMatrix1}[0]}[0..1]");
print("ref to matrix1: $refToExistingMatrix1 : $refToExistingMatrix1->[0]->[0]");

print("array indexing1: $arrayOfInt1[1]");
print("array indexing2: @arrayOfInt1[0..2]");
print("matrix indexing1: $matrixOfInt1[1][2]");
print("matrix indexing2: $matrixOfInt1[1]->[2]");
print("matrix indexing3: @{$matrixOfInt1[1]}[0..2]");

print("arrayOfInt1End = $arrayOfInt1End");
print("string1 = $string1\nint1 = $int1");
#no interlpolation of variables in single quoted strings
print('string1 = $string1\nint1 = $int1');
print("print array1 = @arrayOfInt1");
print "Function calls do"," not require parenthesis.";
print("foreach loop over array");
print("array indexing: $arrayOfInt1[1]");
print("multiple values from array: @arrayOfInt1[1,3,4,2]");
print("multiple values from array in range: @arrayOfInt1[3..6]");
print("string concat1: ",$stringConcat1);
print("string concat2: ", $stringConcat2);


if ($int1>13) {
    print("if branch"); 
} elsif($int1>12) {
    print("elsif branch"); 
} unless($int1>12) {
    print("unless branch"); 
} else {
    print("else branch"); 
}
foreach(@arrayOfInt1) {
    #print "$_";
}
for (my $i=0;$i<$#arrayOfInt1;$i++) {
    #print($arrayOfInt1[$i]);
}

