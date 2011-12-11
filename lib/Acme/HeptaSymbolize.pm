package Acme::HeptaSymbolize;
use strict;
use warnings;
use List::Util 'shuffle';
our $VERSION = '0.02';

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
    my $ttnum = 0;
    my @tnlines = map {
        length $_ ? [ map { length } split /([^ ]+)/ ] : undef;
    } split /\n/, $shape;
    for my $r (grep $_, @tnlines) {
        for my $i (0 .. $#$r) {
            if ($i & 1) {
                $ttlen += $r->[$i];
                $ttnum++;
            }
        }
    }

    # tokenize
    my @ptok = $symbolized =~ /[().^~]|\'\'|=[=~]|.../g;
    if (($shape =~ /(\S+)/ ? length $1 : 0) == 3) {
        $ptok[0] = "'" . (qw/= ~ ( ) . ^/[rand 6]) . "'";
    }
    # TODO(edge case): start with '## # ' or '### # '

    # fill estimated spaces
    if ((my $shortage = $ttlen - length $symbolized) > 0) {
        # ???
        $shortage -= $ttnum;
        # 0x0A
        while ($shortage > 32) {
            my @padding = ('.', '(');
            for my $c (shuffle(qw/1 '.' '=' '('/)) {
                push @padding, $c eq '1' ? (qw/( '' == '' ) . ''/) : ($c), '^';
            }
            $padding[-1] = ')';
            splice @ptok, $#ptok - 24, 0, @padding;
            $shortage -= 26;
        }
        # 0x20
        while ($shortage > 16) {
            my @padding = ('.', '(');
            for my $c (shuffle(qw/'^' '~'/)) {
                push @padding, $c, '^';
            }
            $padding[-1] = ')';
            splice @ptok, $#ptok - 24, 0, @padding;
            $shortage -= 10;
        }
    }

    my $sidx = 0;
    for my $rline_idx (0 .. $#tnlines) {
        my $rline = $tnlines[$rline_idx];
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
            if ($plen) {
                if ($tlen == $plen) {
                    $outstr .= $ptok[$sidx++];
                    next;
                }
                if ($plen > $tlen) {
                    if ($ptok[$sidx] =~ /^'/) {
                        $outstr .= '(' x $tlen;
                        splice(@ptok, $sidx + 1, 0, (')') x $tlen);
                        next;
                    }
                    else {
                        splice(@ptok, $sidx, 0, qw/. ''/);
                        redo;
                    }
                }
            }
            my $fexact = 0;
            my $n = _guess_ntok(\@ptok, $sidx, $tlen, \$fexact);
            if ($fexact) {
                if ($sidx + $n == @ptok &&
                        ($rline_idx < $#tnlines || $it < $#$rline)) {
                    splice @ptok, $#ptok, 0, qw/. ''/;
                    redo;
                }
                $outstr .= join("", @ptok[$sidx .. $sidx + $n - 1]);
                $sidx += $n;
                next;
            }
            my $str;
            --$n while $n > 0 && ! defined($str = _pour_chunk(\@ptok, $sidx, $n, $tlen));
            if ($n) {
                $outstr .= $str;
                $sidx += $n;
                next;
            }
        }
        $outstr .= "\n";
    }

    if ($sidx < @ptok) {
        $outstr .= "\n" . join("", @ptok[$sidx .. $#ptok]);
    }

    return $outstr;
}

sub _guess_ntok {
    my ($rtok, $sidx, $slen, $rexact) = @_;
    my $tlen = 0;
    for my $i ($sidx .. $sidx + $slen) {
        unless ($rtok->[$i]) {
            my $space = $slen - $tlen;
            my @padding = ('.');
            if ($space > 8) {
                push @padding, qw/( ~ '' )/;
            }
            else {
                if ($space % 3 == 2) {
                    push @padding, qw/( '' )/;
                }
                if ($space % 3 == 1) {
                    push @padding, qw/~ ''/;
                }
                if ($space % 3 == 0) {
                    push @padding, qw/''/;
                }
            }
            splice @{$rtok}, $#{$rtok}, 0, @padding;
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
        splice @{$rtok}, $eidx + 2, 0, (')' x $d);
        return join('', @{$rtok}[$sidx .. $eidx], '(' x $d);
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
