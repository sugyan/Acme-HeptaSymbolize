use strict;
use warnings;
use Test::Base;

use File::Temp;

plan tests => 2 * blocks;

run {
    my $block = shift;

    my $tmp  = File::Temp->new;
    my $file = $tmp->filename;
    print $tmp $block->input;
    qx($^X -MAcme::HeptaSymbolize $file);

    my $symbolized = join('', <$tmp>);
    like($symbolized, qr/^[\'\=\~\(\)\.\^]+$/, '7 symbols');

    my $result = qx($^X $file);
    is($result, $block->expected, 'executed result');
};

__DATA__

=== print "1"
--- input
print 1
--- expected: 1

=== print "Hello world!"
--- input
print "Hello world!\n"
--- expected
Hello world!
