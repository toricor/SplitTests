package SplitTests::TestResult;

use strict;
use warnings;
use utf8;

use Mouse;

has mangled_name => (
    is      => 'ro',
    isa     => 'Str',
    required => 1,
);

has test_path => (
    is      => 'ro',
    isa     => 'Str',
    required => 1,
);

has time => (
    is      => 'ro',
    isa     => 'Num',
    required => 1,
);

__PACKAGE__->meta->make_immutable();
no Mouse;

1;
