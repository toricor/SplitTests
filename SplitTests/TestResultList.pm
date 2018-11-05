package SplitTests::TestResultList;

use strict;
use warnings;
use utf8;

use Mouse;

has test_results => (
    is      => 'ro',
    isa     => 'ArrayRef[SplitTests::TestResult]',
    required => 1,
);

__PACKAGE__->meta->make_immutable();
no Mouse;

1;
