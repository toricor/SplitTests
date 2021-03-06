use Test::Spec;
use Test::Mock::Guard qw/mock_guard/;
use SplitTests;

describe 'split_tests' => sub {
    my %host_to_joined_paths;
    before all => sub {
        my $result_guard = mock_guard('SplitTests', +{ '_get_all_results_from_xml' => sub {
            return [
                +{
                     errors   => 0,
                     failures => 0,
                     name     => "t_add_t",
                     skipped  => 0,
                     tests    => 7,
                     time     => 5.0,
                 }, +{
                     errors   => 0,
                     failures => 0,
                     name     => "t_edit_t",
                     skipped  => 0,
                     tests    => 7,
                     time     => 20.0,
                 }, +{ 
                     errors   => 0,
                     failures => 0,
                     name     => "t_lookup_t",
                     skipped  => 0,
                     tests    => 7,
                     time     => 10.0,
                 }, +{ 
                     errors   => 0,
                     failures => 0,
                     name     => "t_delete_t",
                     skipped  => 0,
                     tests    => 7,
                     time     => 3.0,
                 }, +{ 
                     errors   => 0,
                     failures => 0,
                     name     => "t_contained_only_in_previous_test_t",
                     skipped  => 0,
                     tests    => 7,
                     time     => 15.0,
                 },
            ];
        }});
        my $all_test_paths_guard = mock_guard('SplitTests', +{'_get_all_test_paths' => sub {
            return [
                't/add.t',
                't/edit.t',
                't/lookup.t',
                't/delete.t',
                't/not_existed_in_previous_result1.t',
                't/not_existed_in_previous_result2.t',
                't/not_existed_in_previous_result3.t',
                't/not_existed_in_previous_result4.t',
            ];
        }});
        my $output_guard = mock_guard('SplitTests', +{'_output_result' => sub { 
            my @args = @_;
            $host_to_joined_paths{$args[1]} = $args[2];
        }});
        my $_shuffle_guard = mock_guard('SplitTests', +{'_shuffle' => sub {
            my @args = @_;
            return $args[1];
        }});

        SplitTests->new(+{
            host_count => 3,
            print_only => 1,
        })->run();
    };
    
    it 'should split tests into roughly correct size groups' => sub {
        my @test_targets_0 = split(' ', $host_to_joined_paths{0});
        my @test_targets_1 = split(' ', $host_to_joined_paths{1});
        my @test_targets_2 = split(' ', $host_to_joined_paths{2});
        cmp_bag \@test_targets_0, [
            't/delete.t',                          # 3.0 
            't/edit.t',                            # 20.0
            't/not_existed_in_previous_result3.t', # no data
        ];
        cmp_bag \@test_targets_1, [
            't/add.t',                             # 5.0
            't/not_existed_in_previous_result1.t', # no data
            't/not_existed_in_previous_result4.t', # no data
        ];
        cmp_bag \@test_targets_2, [
            't/lookup.t',                          # 10.0
            't/not_existed_in_previous_result2.t', # no data
        ];
    };
};

runtests unless caller;
