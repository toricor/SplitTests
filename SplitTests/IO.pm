package SplitTests::IO;
use strict;
use warnings;
use utf8;

sub read_file {
    my ($self, $file_path) = @_;
    return unless -e $file_path;
    open my $fh, '<', $file_path;
    my $content = do { local $/; <$fh> };
    close $fh;
    return $content;
}

sub write_file {
    my ($self, $file_path, $content) = @_;
    open my $fh, '>', $file_path;
    print $fh $content;
    close $fh;
}

1;
