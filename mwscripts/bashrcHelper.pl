#!/usr/bin/perl 
use strict;
use warnings;


my $command = $ENV{"PPP_COMMAND"};

if ($command eq "chd") {
    chd();
} elsif ($command eq "p4o") {
    p4o();
}

sub p4o {
    my $p4opened = $ENV{"PPP_P4OPENED"};
    my $sbroot = $ENV{"PPP_SBROOT"};
    my $sbver = $ENV{"PPP_SBVER"};
    my @sbvers = split("\n", $sbver);
    my $stream = "//mw/Bstateflow_2";
    foreach(@sbvers) {
        my @streams=split("Stream: ",$_);
        if($#streams>=1) {
            $stream=$streams[1];
        }
    }
    my @lines = split("\n", $p4opened);
    foreach(@lines) {
        my @line = split("#",$_);
        my $file = $line[0];
        $file =~ s/$stream/$sbroot/ig;
        print ($file . " ");
    }

}


sub chd {
    my $d = $ENV{"d"};
    my $s = $ENV{"s"};
    my $MYSBROOT = $ENV{"MYSBROOT"};
    my $MYSBNAME = $ENV{"MYSBNAME"};
    my %DirectoryShortCutMappings = (
        'gitroot',"$d/gitRepo1/",
        'mygit',"$d/gitRepo1/pppGitHub/",
        'conf',"$s/misc/configurations/",
        'lang',"$d/gitRepo1/pppGitHub/lang",
        'notes',"$d/gitRepo1/pppGitHub/notes",
        'mwscripts',"$d/gitRepo1/pppGitHub/mwscripts",
        "4: sfroot","$MYSBROOT/matlab/toolbox/stateflow/src/",
        "3: sftest","$MYSBROOT/matlab/test/toolbox/stateflow",
        "2: matlabroot","$MYSBROOT/matlab",
        "1: $MYSBNAME","$MYSBROOT",
    );
    my @directoryKeys=sort(keys(%DirectoryShortCutMappings));
    #my @directoryKeys=keys(%DirectoryShortCutMappings);
    my $counter = 0;
    foreach(@directoryKeys) {
        $counter = $counter + 1;
        my $key=$_;
        my $value=$DirectoryShortCutMappings{$key};

        my $dirnum = $ENV{"PPP_DIRECTORYNUMBER"};
        if ($dirnum == -1) {
            #print("$counter : $key : $value\n");
            print("$counter : $key \n");
        } elsif($dirnum==$counter) {
            print($value);
        }
    }
}

