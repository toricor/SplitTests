use Test::Spec;
use Test::Mock::Guard qw/mock_guard/;
use SplitTests; 

use constant {
    TEST_RESULT_FILE_PREFIX => 'junit_output',
};

describe '_read_results_from_xml' => sub {
    context 'xml file does not contain any data' => sub {
        my $hash_array;
        before each => sub {
            my $xml = undef; 
            my $read_file_guard = mock_guard('SplitTests::IO', +{ read_file => sub { $xml }});
            $hash_array = SplitTests->_read_results_from_xml(TEST_RESULT_FILE_PREFIX.'0.xml');
        };
        it 'should return empty arrayref' => sub {
            is @$hash_array, 0;
        };
    };
    context 'invalid xml' => sub {
        my $hash_array;
        before each => sub {
            my $xml = <<EOT 
<?xml version='1.0' encoding='utf-8'?>
<testsuites>
  <testsuite name="t_add_t" errors="0" failures="0" skipped="0" tests="2" time="5.01">
    <system-out>
  </testsuite>
</testsuites>
EOT
;
            my $read_file_guard = mock_guard('SplitTests::IO', +{ read_file => sub { $xml }});
            local $SIG{__WARN__} = sub {};
            $hash_array = SplitTests->_read_results_from_xml(TEST_RESULT_FILE_PREFIX.'1.xml');
        };
        it 'should return empty arrayref' => sub {
            is @$hash_array, 0;
        };
    };
    context 'valid xml' => sub {
        my $hash_array;
        before each => sub { 
            my $xml = <<EOT 
<?xml version='1.0' encoding='utf-8'?>
<testsuites>
  <testsuite name="t_add_t" errors="0" failures="0" skipped="0" tests="2" time="5.01">
    <system-out># »» basic
ok 1 - L18: 追加前は0件(0 before add)
ok 2 - L30: Hoge
1..2
</system-out>
    <testcase name="L18: 追加前は0件(0 before add)" classname="t_add_t" time="0.053088903427124" />
    <testcase name="L30: Hoge" classname="t_add_t" time="0.00304198265075684" />
  </testsuite>
  <testsuite name="t_all_t" errors="0" failures="0" skipped="0" tests="3" time="15.01">
    <system-out># »» basic
ok 1 - L37: 'Entity is right' isa 'Help::List'
ok 2 - L39: HOGE
# »»»» ORDER
ok 3 - L41: FUGA
1..3
</system-out>
    <testcase name="L37: 'Entity is right' isa 'Help::List'" classname="t_all_t" time="0.0538270473480225" />
    <testcase name="L39: HOGE" classname="t_all_t" time="0.000203132629394531" />
    <testcase name="L41: FUGA" classname="t_all_t" time="0.000154972076416016" />
  </testsuite>
</testsuites>
EOT
;
            my $read_file_guard = mock_guard('SplitTests::IO', +{ read_file => sub { $xml }});
            $hash_array = SplitTests->_read_results_from_xml(TEST_RESULT_FILE_PREFIX.'1.xml');
        };
        it 'should return valid hash array' => sub {
            cmp_deeply $hash_array, [+{
                errors   => 0,
                failures => 0,
                name     => 't_add_t',
                skipped  => 0,
                tests    => 2,
                time     => 5.01,
            }, +{
                errors   => 0,
                failures => 0,
                name     => 't_all_t',
                skipped  => 0,
                tests    => 3,
                time     => 15.01,
            }];
        };
    };
};

runtests unless caller;

