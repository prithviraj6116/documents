package myperlmodule1;

use strict;
use warnings;
sub myperlmodule1f1 {
    print "myperlmodule1 : entry";
}
myperlmodule1f1();
BEGIN{print "module begin";}

1;
