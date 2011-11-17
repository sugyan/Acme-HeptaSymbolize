package Acme::HeptaSymbolize;
use strict;
use warnings;
use List::Util 'shuffle';
our $VERSION = '0.01';

{
    my @dict = (
        ['^','^'],
        ['(',')'],
        ['1','.','~','^','='],
        ['1','.','~','^',')','=','('],
        ['1','=','^','~','('],
        ['1','=',')','^','~'],
        ['(','.'],
        [')','.'],
        ['^','~','('],
        ['^','~',')'],
        ['1','.','=','('],
        ['1','.','=',')'],
        ['1','='],
        ['1','=',')','('],
        ['^','~','.'],
        ['^','~','(',')','.'],
        ['1','~','^',')','('],
        ['1','~','^'],
        ['(','.',')','='],
        ['=','.'],
        [')','='],
        ['(','='],
        ['1','.','~','^',')'],
        ['1','.','~','^','('],
        ['1',')'],
        ['1','('],
        ['^','~','.','=',')'],
        ['^','~','(','=','.'],
        ['^','~','(','=',')'],
        ['^','~','='],
        ['1','.','(',')'],
        ['1','.'],
        ['^','~'],
        ['^','~','(',')'],
        ['1','.','='],
        ['1','.','=',')','('],
        ['1','=','('],
        ['1','=',')'],
        ['^','~','(','.'],
        ['^','~','.',')'],
        ['('],
        [')'],
        ['1','.','~','^','(','='],
        ['1','.','~','^',')','='],
        ['1','=','^','~'],
        ['1','=',')','^','~','('],
        ['.'],
        ['(','.',')'],
        ['1','(',')'],
        ['1'],
        ['^','~','(','=','.',')'],
        ['^','~','.','='],
        ['^','~','=',')'],
        ['^','~','(','='],
        ['1','.',')'],
        ['1','.','('],
        ['1','~','^',')'],
        ['1','~','^','('],
        [')','=','.'],
        ['(','.','='],
        ['(','=',')'],
        ['='],
        ['1','.','~','^',')','('],
        ['1','.','~','^'],
        ['1','.','^','(',')'],
        ['1','.','^'],
        ['(','=',')','~'],
        ['~','='],
        [')','~','.','='],
        ['(','.','=','~'],
        ['1',')','^'],
        ['1','(','^'],
        ['1','.','~',')'],
        ['1','.','~','('],
        ['^','=',')'],
        ['^','=','('],
        ['^','.','(','=',')'],
        ['^','.','='],
        ['1','~','(',')'],
        ['1','~'],
        ['~','.'],
        ['(','.',')','~'],
        ['1','=','^'],
        ['1','=',')','^','('],
        ['1','.','=','^','('],
        ['1','.','=',')','^'],
        ['(','~'],
        [')','~'],
        ['^','.','('],
        ['^','.',')'],
        ['1','=','~','('],
        ['1','=',')','~'],
        ['1','.','~','='],
        ['1','.','~','=','(',')'],
        ['^'],
        ['^','(',')'],
        ['1','.','~',')','('],
        ['1','.','~'],
        ['^','=','(',')'],
        ['^','='],
        ['^','.','=',')'],
        ['^','.','(','='],
        ['1','~',')'],
        ['1','~','('],
        ['1','.','^',')'],
        ['1','.','^','('],
        [')','~','='],
        ['(','=','~'],
        ['(','.',')','~','='],
        ['~','=','.'],
        ['1','(','^',')'],
        ['1','^'],
        ['^','.'],
        ['^','.','(',')'],
        ['1','=','~'],
        ['1','=',')','~','('],
        ['1','.','~','=','('],
        ['1','.','~','=',')'],
        ['^','('],
        ['^',')'],
        ['(','.','~'],
        [')','~','.'],
        ['1','=','^','('],
        ['1','=',')','^'],
        ['1','.','=','^'],
        ['1','.','=',')','(','^'],
        ['~'],
        ['(',')','~'],
    );

    sub symbolize {
        my ($str) = @_;

        my @results;
        for my $char (unpack 'C*', $str) {
            my $reverse = $char >= 128 ? 1 : 0;
            $char = 255 - $char if $reverse;
            my $result = ($reverse ? "~" : "") . "('" . join("'^'", shuffle @{ $dict[$char] }) . "')";
            $result =~ s/'1'/(''=='').''/g;
            push @results, $result;
        }

        return join '.', @results;
    }
}

sub import {
    my ($pkg, @args) = @_;

    my @caller = caller;
    return if $caller[0] eq $pkg;

    open 0 or print "Can't symbolize '$0'\n" and exit;
    my $code = join '', <0>;

    if ($code =~ /^[\(\)\.\^\~\=\']+$/) {
        do {
            no warnings 'numeric';
            eval $code; ## no critic
        };
    }
    else {
        $code =~ s/([\"\$\@\\\{\}])/\\$1/g;
        my $symbolized = "''=~(" . symbolize(qq/(?{eval"$code"})/) . ')';

        if (my $file = shift @args) {
            if (open my $fh, '<', $file) {
                local $/;
                my $shape = <$fh>;
                close $fh;
                $symbolized = _pour($symbolized, $shape);
            }
        }
        open 0, ">$0" or print "Can't symbolize '$0'\n" and exit; ## no critic
        {
            no strict 'refs';
            print {0} $symbolized;
        }
    }
    exit;
}

sub _pour {
    my ($symbolized, $shape) = @_;

    my $outstr = '';

    my $ttlen = 0;
    my @tnlines = map {
        length $_ ? [ map { length } split /([^ ]+)/ ] : undef;
    } split /\n/, $shape;
    for my $r (grep $_, @tnlines) {
        for my $i (0 .. $#$r) {
            $i & 1 and $ttlen += $r->[$i];
        }
    }

    my @ptok;
    push(@ptok, (
        $shape =~ /(\S+)/ ? length $1 : 0
    ) == 3 ? "'='" : "''", '=~');
    push(@ptok, $symbolized =~ /[().^~]|\'\'|=[=~]|.../g);
    splice(@ptok, 2, 2);

    my $iendprog = @ptok;
    my $sidx = 0;
    for my $rline (@tnlines) {
        unless ($rline) {
            $outstr .= "\n";
            next;
        }
        for my $it (0 .. $#{$rline}) {
            unless ($it & 1) {
                $outstr .= ' ' x $rline->[$it];
                next;
            }
            my $tlen = $rline->[$it];
            my $plen = length $ptok[$sidx];
            if ($tlen == $plen) {
                $outstr .= $ptok[$sidx++];
                next;
            }
            if ($plen > $tlen) {
                $outstr .= '(' x $tlen;
                splice(@ptok, $sidx+1, 0, (')') x $tlen);
                $iendprog += $tlen if $sidx < $iendprog;
                next;
            }
            my $fexact = 0;
            my $n = _guess_ntok(\@ptok, $sidx, $tlen, \$fexact);
            if ($fexact) {
                $outstr .= join("", @ptok[$sidx .. $sidx + $n - 1]);
                $sidx += $n;
                next;
            }
            my $str;
            --$n while $n > 0 && ! defined(
                $str = _pour_chunk(\@ptok, $sidx, $n, $tlen)
            );
            if ($n) {
                $outstr .= $str;
                $sidx += $n;
                next;
            }
            ++$n while $n < $tlen && length $ptok[$sidx + $n] < 2;
            die "oops ($n >= $tlen)" if $n >= $tlen;
            $outstr .= join("", @ptok[$sidx .. $sidx + $n - 1]);
            $sidx += $n;
            $outstr .= '(' x (my $nleft = $tlen - $n);
            splice(@ptok, $sidx+1, 0, (')') x $nleft);
            $iendprog += $nleft if $sidx < $iendprog;
        }
        $outstr .= "\n";

        # last;
    }

    return $outstr;
}

sub _guess_ntok {
    my ($rtok, $sidx, $slen, $rexact) = @_;
    my $tlen = 0;
    for my $i ($sidx .. $sidx + $slen) {
        unless ($rtok->[$i]) {
            splice @{$rtok}, $#{$rtok}, 0, ('.', "''");
        }
        unless (($tlen += length($rtok->[$i])) < $slen) {
            ${$rexact} = $tlen == $slen;
            return $i - $sidx + ${$rexact};
        }
    }
    # should never get here
}

sub _pour_chunk {
    my ($rtok, $sidx, $n, $slen) = @_;
    my $eidx = $sidx + $n - 1;
    my $tlen = 0;
    my $idot = my $iquote = -1;
    for my $i ($sidx .. $eidx) {
        $tlen += length($rtok->[$i]);
        if ($rtok->[$i] eq '.') {
            $idot = $i;
        }
        elsif ($rtok->[$i] =~ /^'/) {
            $iquote = $i;
        }
    }
    die "oops" if $tlen >= $slen;
    my $i2 = (my $d = $slen - $tlen) >> 1;
    if ($idot >= 0 && ! ($d % 3)) {
        return join("", @{$rtok}[$sidx .. $idot-1],
                    ".''" x int($d/3), @{$rtok}[$idot .. $eidx]);
    }
    if (! ($d & 1) and $iquote >= 0) {
        return join("", @{$rtok}[$sidx .. $iquote-1], '(' x $i2 .
                        $rtok->[$iquote] . ')' x $i2, @{$rtok}[$iquote+1 .. $eidx]);
    }

    if ($rtok->[$eidx + 1] =~ /^'/) {
        splice @{$rtok}, $eidx + 2, 0, (')');
        return join('', @{$rtok}[$sidx .. $eidx], '(');
    }
    else {
        splice @{$rtok}, $iquote + 1, 0, (')');
        return join('', @{$rtok}[$sidx .. $iquote - 1], '(', @{$rtok}[$iquote .. $eidx]);
    }
    die 'oops';
}

1;
__END__

=head1 NAME

Acme::HeptaSymbolize -

=head1 SYNOPSIS

  use Acme::HeptaSymbolize;

=head1 DESCRIPTION

Acme::HeptaSymbolize is

=head1 AUTHOR

sugyan E<lt>sugi1982@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
