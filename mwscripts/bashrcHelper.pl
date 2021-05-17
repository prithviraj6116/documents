#!/usr/bin/perl 
use strict;
use warnings;


my $d = $ENV{"d"};
my %DirectoryShortCutMappings = (
    'gitroot',"$d/gitRepo1/",
    'mygit',"$d/gitRepo1/pppGitHub/",
    'mwscripts',"$d/gitRepo1/pppGitHub/mwscripts"
);
my @directoryKeys=sort(keys(%DirectoryShortCutMappings));
my $counter = 0;
foreach(@directoryKeys) {
    $counter = $counter + 1;
    my $key=$_;
    my $value=$DirectoryShortCutMappings{$key};
    
    my $dirnum = $ENV{"PPP_DIRECTORYNUMBER"};
    if ($dirnum == -1) {
        print("$counter : $key : $value\n");
    } elsif($dirnum==$counter) {
        print($value);
    }
}


