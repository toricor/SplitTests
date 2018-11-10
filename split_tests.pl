use SplitTests;
use strict;
use warnings;
use utf8;
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);

GetOptions(
    \my %opt, qw/
        hosts=s
        print_only
    /
);

SplitTests->new(+{
    hosts      => $opt{'hosts'},
    print_only => $opt{'print_only'},
})->run();
