requires 'XML::LibXML';
requires 'List::AllUtils', '0.14';
requires 'Mouse';

on 'test' => sub {
    requires 'Test::Mock::Guard';
    requires 'Test::Spec';
};
