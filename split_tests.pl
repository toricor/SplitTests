use SplitTests;
use strict;
use warnings;
use utf8;
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);

GetOptions(
    \my %opt, qw/
        host_count=i
        print_only
    /
);

SplitTests->new(+{
    host_count => $opt{'host_count'},
    print_only => $opt{'print_only'},
})->run();
