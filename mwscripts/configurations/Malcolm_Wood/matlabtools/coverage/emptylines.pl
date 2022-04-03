#!/usr/local/bin/perl

# process m-files for code coverage

my $line_number = 0;
my $executable_line_count = 0;

# function_line_continued is a special case of continued lines.
# When we are trying to count executable lines, the function
# keyword is the only non-executable keyword that can have 
# continuations after it.  We don't want to count any lines
# from the function declaration as executable.
my $function_line_continued = 0;
my $in_function = 0;
my $function_string = "";
my $function_executable_line_count = 0;
my $revision = undef;

my @empty = ();
my @continued = ();
my @functions = ();
my @function_names = ();
my @function_executable_lines = ();
my @comments = ();

# these global variables keep track of the current
# number of unmatched braces or brackets 
my $open_brackets = 0;
my $open_braces = 0;

foreach(<STDIN>) {
    $line_number++;

    # check for the maple file format tag
    # if it is there, don't process this file.
    if (($line_number == 1) && /\s*MVR5\s*/){
    	# print "in if with : $_\n";
    	$line_number = 0;
    	last;
    }
    # try to capture the revision from file
    # % $Revision: 1.1 $
    if(!$revision && /%.*Revision/)
    {
	$revision = $1 if /%.*\$Revision\:\s*([\d|\.]*)\s*\$/;
    }
    # prepare the line for parsing
    $_ = remove_strings($_) if /\'/;
    $_ = remove_comments($_) if /\%/;

    # send this line to check for open brackets or braces
    check_open_paren($_);
    # if the function line has been continued, build up the function
    # name
    if($function_line_continued){
	$function_string = append_function_string($function_string, $_);
    }

    # any lines with only comments or nothing at all are 
    # empty, non-executable lines
    if( /^\s*$/ ) {
	push(@empty, $line_number);
    } # because of a notation style for arrays and cell arrays
      # we must count all lines within a cell array or array.
    elsif ( /\.\.\./ || open_parens()) {
	# we are on a continued line so add it to the 
	# continued line list
	push(@continued, $line_number);
	
        # if this is a continued function line
	if ( /^function/ ){
	    # store the line number in the function list
	    push(@functions, $line_number);
	    # since we are on a continued line also
	    # set function_line_continued to true
	    $function_line_continued = 1;
	    # take the string and store the string in 
	    # the function_string variable for use later
	    $function_string = append_function_string($function_string, $_);
	    # if $in_function is true then what we are
	    # currently looking at is a new function line
	    # store the function line count, and reset the
	    # counter to start counting the new function 
	    # executable lines
	    if($in_function){
		push(@function_executable_lines, $function_executable_line_count);
		$function_executable_line_count = 0;
	    } else {
		$in_function = 1;
	    }
	}
    } # if this line starts with the function keyword 
    elsif ( /^function/ ){
	push(@functions, $line_number);
	push(@function_names, get_function_name($_));
	# if $in_function is true then what we are
	# currently looking at is a new function line
	# store the function line count, and reset the
	# counter to start counting the new function 
	# executable lines
	if($in_function){
	    push(@function_executable_lines, $function_executable_line_count);
	    $function_executable_line_count = 0;
	} else {
	    $in_function = 1;
	}
    } # if we are in function line that has been continued
      # but we are at the last line of that function, change
      # $function_line_continued to false to start counting
      # executable lines again.
    elsif ( $function_line_continued ) {
	$function_line_continued = 0;
	push(@function_names, get_function_name($function_string));
	$function_string = "";
    } # this is an executable line, increment the counters
    else {
	$executable_line_count++;
	$function_executable_line_count++;
    }
}

# once we finish reading the file, we push the last count
# of a function's executable lines onto the list of executable
# lines
push(@function_executable_lines, $function_executable_line_count);

# display empty lines, continued lines, function lines, and the length
# of the file
print "COVER_EMPTY:";
foreach (@empty) {
    print "$_ ";
}
print "\nCOVER_CONTINUED:";
foreach (@continued) {
    print "$_ ";
}
print "\nCOVER_FUNCTIONS:";
foreach (@function_names) {
    print "$_ ";
}
print "\nCOVER_FUNCTION_LINES:";
foreach(@functions){
    print "$_ ";
}

print "\nCOVER_FUNCTION_NUMBER_OF_EXECUTABLE_LINES:";
foreach(@function_executable_lines){
    print "$_ ";
}

print"\nCOVER_NUMBER_OF_EXECUTABLE_LINES:";
print $executable_line_count;

print "\nCOVER_NUMBER_OF_LINES:";
print $line_number;

print "\nCOVER_REVISION:";
print $revision;

print "\n";

# check a line to see if it has unmatched braces or brackets
sub check_open_paren {

    my($check_this) = @_;
    # calculate the number of outstanding brackets or braces
    $open_braces = $open_braces + ($check_this =~ s/\{/\{/g) - 
	($check_this =~ s/\}/\}/g);
    $open_brackets = $open_brackets + ($check_this =~ s/\[/\[/g) - 
	($check_this =~ s/\]/\]/g);
}

# returns true if the file currently has unmatched braces,
# or brackets
sub open_parens {
    return (($open_braces != 0) || ($open_brackets != 0));
}

# append a string to another, preparing if for parsing
# by get_function_name
sub append_function_string {
    my($function_string, $append_string) = @_;
    # chop off all continuation characters and new_lines
    $append_string =~ s/\.\.\.\s*//;
    # strip out any white space
    $append_string =~ s/\s*//;
    #append the two strings together
    $function_string = "$function_string$append_string";
    # return the new long string
    return $function_string;
}

# parse the name of a function out of string
sub get_function_name {
    my($function_string) = @_;

    # if the string has an equals symbol in it
    # chop off everything up to the symbol
    if($function_string =~ /.*=.*/){
	$function_string =~ s/^function.*=//;
    } # otherwise just chop off the function
      # keyword and any whitespace following it 
    else {
	$function_string =~ s/^function\s*//;
    }

    # get the name of the function from the 
    # remaining string and return it
    $function_string =~ /\s*(\w+)\s*\({0,1}.*?/;    
    return $1;
}

# removes all characters following a '%'
sub remove_comments {
    my($string) = @_;
    $string =~ s/%.*//g;
    return $string;
}

# removes all double quotes and strings within
# quotes
sub remove_strings {
    my($string) = @_;
    my $open_quotes = 0;
    my $quote_index = 0;
    my $quoted_substring = '';

    # remove all quote pairs
    $string =~ s/\'{2}//g;

    # we need to be safe in here.  Make sure that the string
    # is actually a string and not a transposed matrix
    $quote_index = index($string, "'", $quote_index);
    while( $quote_index >= 0){
	# if $quote_index is 0, we're looking at the first
	# character of a line and we know that it is an
	# opening quote and not a transpose operator
	if($quote_index > 0){
	    $quoted_substring = substr($string, $quote_index - 1, 2);
	    # check to see if it might be a transpose character
	    if( ( $quoted_substring =~ /(\w|\)|\]|\.)/ ) & !$open_quotes ){
		# this is a transpose character so just replace it
		# with a big ol' 'T'
		substr($string, $quote_index, 1) = 'T';
	    }
	    # otherwise check to see if it is a closing quote
	    elsif ( $open_quotes ) {
		$open_quotes = 0;
	    } 
	    # otherwise it is an opening quote
	    else {
		$open_quotes = 1;
	    }
	} 
        # this is an opening quote, so mark that we have found one 
	else {
	    $open_quotes = 1;
	}
	$quote_index = index($string, "'", $quote_index + 1);
    }
    
    # remove all remaining strings
    $string =~ s/\'.*?\'/STRING_REPLACE/g;

    return $string;
}

