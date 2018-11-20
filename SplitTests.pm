package SplitTests;
use strict;
use warnings;
use utf8;
use feature qw/say/;
use version; our $VERSION = version->declare('v0.0.1');

use File::Find;
use List::AllUtils qw/part shuffle/;
use XML::LibXML;

use SplitTests::IO;
use SplitTests::TestResult;
use SplitTests::TestResultList;

use constant {
    TEST_RESULT_FILE_PREFIX => 'junit_output',
    OUTPUT_PREFIX           => 'test_targets',
};
my @TEST_DIRS = ('t/');

use Mouse;
has hosts => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has print_only => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0, 
);

# all test file paths in TEST_DIR
has _all_paths => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    builder  => sub {
        my $self = shift;
        $self->_get_all_test_paths(\@TEST_DIRS)
    },
);

has _mangled_name_to_test_path => (
    is      => 'ro',
    isa     => 'HashRef',
    builder => sub {
        my $self = shift;
        $self->_make_mangled_name_to_test_path($self->_all_paths)
    },
);

sub run {
    my ($self) = @_;
    my @hosts = split(',', $self->hosts);
    my $test_result_list = SplitTests::TestResultList->new(
        test_results => [ map {
            SplitTests::TestResult->new(
                mangled_name => $_->{name},
                test_path    => ${$self->_mangled_name_to_test_path}{$_->{name}},
                time         => $_->{time},
            )
        } grep {
            exists $self->_mangled_name_to_test_path->{$_->{name}} # acquire tests in t/
        } @{$self->_get_all_results_from_xml(\@hosts)}]
    );
    
    my ($sorted_result_test_paths, $not_in_result_test_paths) = $self->_split_test_path_groups($test_result_list);

    my $i = 0;
    my $path_groups = $self->_shuffle([ part { $i++ % scalar(@hosts)} (@$sorted_result_test_paths, @{$self->_shuffle($not_in_result_test_paths)}) ]);
    
    for my $idx (0..$#hosts) {
        my $paths_for_host = $path_groups->[$idx];
        my $joined_paths = join(' ', shuffle @$paths_for_host);
        $self->_output_result($hosts[$idx], $joined_paths);
    }
}

sub _shuffle {
    my ($self, $targets) = @_;
    return [ shuffle @$targets ];
}

sub _output_result {
    my ($self, $host, $joined_paths) = @_;
    if ($self->print_only) {
        say $joined_paths;
    } else {    
        SplitTests::IO->write_file(OUTPUT_PREFIX."_$host", $joined_paths);
    }
};

sub _get_all_test_paths {
    my ($self, $test_dirs) = @_;
    my @all_tests = ();
    find({ wanted => sub {
        -f $_ or return;
        my @splited = split(/\./, $_);
        return unless scalar(@splited);
        my $extention = $splited[$#splited];
        if ($extention eq "t"){
            push @all_tests, $File::Find::name;
        }
    }, no_chdir => 0}, @$test_dirs);
    unless (scalar(@all_tests)) {
        die "no test file is detected";
    }
    return \@all_tests;
}

sub _split_test_path_groups {
    my ($self, $test_result_list) = @_;

    my @sorted_result_test_paths = map {$_->test_path} sort {$a->time <=> $b->time} @{$test_result_list->test_results};
    my %result_test_path_hash    = map {$_ => 1} @sorted_result_test_paths;
    my @not_in_result_test_paths = grep {not exists $result_test_path_hash{$_}} @{$self->_all_paths};
    return (\@sorted_result_test_paths, \@not_in_result_test_paths);
}

sub _get_all_results_from_xml {
    my ($self, $hosts) = @_;
    my @test_results = ();
    for my $host (@$hosts) {
        my $hash_array_from_xml = $self->_read_results_from_xml(TEST_RESULT_FILE_PREFIX."_${host}.xml");
        push(@test_results, @$hash_array_from_xml);
    }
    return \@test_results;
}

sub _read_results_from_xml {
    my ($self, $file_path) = @_;
    my $content = SplitTests::IO->read_file($file_path);
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


sub _make_mangled_name_to_test_path {
    my ($self, $test_paths) = @_;
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

no Mouse;
__PACKAGE__->meta->make_immutable();

1;
