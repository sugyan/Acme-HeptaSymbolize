use inc::Module::Install;
name 'Acme-HeptaSymbolizer';
all_from 'lib/Acme/HeptaSymbolizer.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
