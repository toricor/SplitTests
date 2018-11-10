package SplitTests;
use strict;
use warnings;
use utf8;
use version; our $VERSION = version->declare('v0.0.1');

use File::Find;
use List::AllUtils qw/part shuffle/;
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);
use XML::LibXML;

use SplitTests::TestResult;
use SplitTests::TestResultList;

use constant {
    RESULT_FILE_PREFIX => 'junit_output',
    TEST_DIR => 't/',
};

main();

sub main {
    GetOptions(
        \my %opt, qw/
            hosts=s
        /
    );
    unless ($opt{'hosts'}) {
        warn "hosts are needed";
        return
    }
    my $all_paths = SplitTests->get_all_paths();
    unless (scalar(@$all_paths)) {
        warn "test directory was not detected";
        return
    }
    
    my @hosts = split(',', $opt{'hosts'});
    my $mangled_name_to_test_path = mangled_name_to_test_path($all_paths);

    my $test_result_list = SplitTests::TestResultList->new(
        test_results => [ map {
            SplitTests::TestResult->new(
                mangled_name => $_->{name},
                test_path    => $mangled_name_to_test_path->{$_->{name}},
                time         => $_->{time},
            )
        } grep {
            exists $mangled_name_to_test_path->{$_->{name}} # acquire tests in t/
        } @{get_all_results_from_xml(\@hosts)}]
    );

    my ($sorted_result_test_paths, $not_in_result_test_paths) = _split_test_path_groups($test_result_list, $all_paths);

    my $i = 0;
    my @paths = part { $i++ % scalar(@hosts)} (@$sorted_result_test_paths, @$not_in_result_test_paths);
    for my $idx (0..$#hosts) {
        my $paths_for_host = $paths[$idx];
        my $joined_paths = join(' ', shuffle @$paths_for_host);
        write_file('test_targets_'.$hosts[$idx], $joined_paths);
    }
}

sub get_all_paths {
    my @all_tests;
    find({ wanted => sub {
        -f $_ or return;
        my @splited = split(/\./, $_);
        return unless scalar(@splited);
        my $extention = $splited[$#splited];
        if ($extention eq "t"){
            push @all_tests, $File::Find::name;
        }
    }, no_chdir => 0}, TEST_DIR);
    return \@all_tests;
}

sub _split_test_path_groups {
    my ($test_result_list, $all_paths) = @_;

    my @sorted_result_test_paths = map {$_->test_path} sort {$a->time <=> $b->time} @{$test_result_list->test_results};
    my %result_test_path_hash    = map {$_ => 1} @sorted_result_test_paths;
    my @not_in_result_test_paths = shuffle grep {not exists $result_test_path_hash{$_}} @$all_paths;
    return (\@sorted_result_test_paths, \@not_in_result_test_paths);
}

sub get_all_results_from_xml {
    my ($hosts) = @_;
    my @test_results = ();
    for my $host (@$hosts) {
        my $hash_array_from_xml = read_results_from_xml(RESULT_FILE_PREFIX."_${host}.xml");
        push(@test_results, @$hash_array_from_xml);
    }
    return \@test_results;
}

sub read_results_from_xml {
    my ($file_path) = @_;
    my $content = read_file($file_path);
    return [] unless $content;

    $content =~ s|<system-out>(.*?)</system-out>|<system-out></system-out>|smg;
    my $doc;
    eval {
        $doc = XML::LibXML->new->parse_string($content);
    };
    if ($@) {
        warn "$file_path cannot parse as valid XML";
        return [];
    }

    my @nodelist = $doc->getElementsByTagName('testsuite');
    my @hash_array = ();
    for my $node (@nodelist) {
        my %hash = %{$node->getAttributeHash};
        push @hash_array, \%hash;
    }
    return \@hash_array;
}

sub read_file {
    my ($file_path) = @_;
    return unless -e $file_path;
    open my $fh, '<', $file_path;
    my $content = do { local $/; <$fh> };
    close $fh;
    return $content;
}

sub write_file {
    my ($file_path, $content) = @_;
    open my $fh, '>', $file_path;
    print $fh $content;
    close $fh;
}

sub mangled_name_to_test_path {
    my ($test_paths) = @_;
    my %mangled_name_to_test_path;
    for my $test_path (@$test_paths) {
        my $mangled_name = $test_path;
        $mangled_name =~ s/^[\.\/]*//;
        $mangled_name =~ s/-/_/g;
        $mangled_name =~ s/\./_/g;
        $mangled_name =~ s/\//_/g;
        $mangled_name_to_test_path{$mangled_name} = $test_path;
    }
    return \%mangled_name_to_test_path;
}

1;
