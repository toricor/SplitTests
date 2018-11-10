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

my @hosts = split(',', $opt{'hosts'});
my $status = SplitTests->new(+{
    hosts      => \@hosts,
    print_only => $opt{'print_only'},
})->run();
