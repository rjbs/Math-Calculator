
package Math::Calculator;
$Math::Calculator::VERSION = '1.02';

=head1 NAME

Math::Calculator -- a multi-stack calculator class

=head1 VERSION

version 1.02

 $Id: Calculator.pm,v 1.6 2005/03/06 03:09:16 rjbs Exp $

=head1 SYNOPSIS

 use Math::Calculator;

 my $calc = Math::Calculator->new;

 $calc->push(10, 20, 30);
 $calc->add;
 $calc->root; # 1.0471285480509  (50th root of 10)

=head1 DESCRIPTION

Math::Calculator is a simple class representing a stack-based calculator.  It
can have an arbitrary number of stacks.

=cut

use strict;
use warnings;

=head1 METHODS

=over

=item C<< new >>

This class method returns a new Math::Calculator object with one stack
("default").

=cut

sub new {
	bless {
		stacks => { default => [] },
		current_stack => 'default'
	} => shift
}

=item C<< current_stack($stackname) >>

This method sets the current stack to the named stack.  If no stack by the
given name exists, one is created and begins life empty.  Stack names are
strings of word characters.  If no stack name is given, or if the name is
invalid, the stack selection is not changed.

The name of the selected stack is returned.

=cut

sub current_stack {
	my ($self, $stack) = @_;

	return $self->{current_stack} unless $stack and $stack =~ /^\w+$/;
	$self->{stacks}{$stack} = [] unless defined $self->{stacks}{$stack};
	$self->{current_stack} = $stack;
}

=item C<< stack($stackname) >>

This method returns a (array) reference to the stack named, or the current
selected stack, if none is named.

=cut

sub stack { $_[0]->{stacks}->{$_[1] ? $_[1] : $_[0]->current_stack} }

=item C<< top >>

This method returns the value of the top element on the current stack without
altering the stack's contents.

=cut

sub top   { (shift)->stack->[-1] }

=item C<< clear >>

This clears the current stack, setting it to C<()>.

=cut

sub clear { @{(shift)->stack} = (); }

=item C<< push(@elements) >>

C<push> pushes the given elements onto the stack in the order given.

=item C<< push_to($stackname, @elements) >>

C<push_to> is identical to C<push>, but pushes onto the named stack.

=cut

sub push { push @{(shift)->stack}, @_; }
sub push_to { CORE::push @{(shift)->stack(shift)}, @_; }

=item C<< pop($howmany) >>

This method pops C<$howmany> elements off the current stack, or one element, if
C<$howmany> is not defined.

=item C<< pop_from($stackname, [ $howmany ]) >>

C<pop_from> is identical to C<pop>, but pops from the named stack.

=cut

sub pop { splice @{$_[0]->stack}, - (defined $_[1] ? $_[1] : 1); }
sub pop_from { splice @{$_[0]->stack($_[1])}, - (defined $_[2] ? $_[2] : 1); }

=item C<< from_to($from_stack, $to_stack, [ $howmany ]) >>

This pops a value from one stack and pushes it to another.

=cut

sub from_to { $_[0]->push_to($_[2], $_[0]->pop_from($_[1], $_[3])) }

=item C<< dupe >>

C<dupe> duplicates the top value on the current stack.  It's identical to C<<
$calc->push($calc->top) >>.

=cut

sub dupe { $_[0]->push( $_[0]->top ); }

=item C<< _op_two($coderef) >>

This method, which is only semi-private because it may be slightly refactored
or renamed in the future (possibly to operate on I<n> elements), pops two
elements, feeds them as parameters to the given coderef, and pushes the result.

=cut

# sub _op_two { $_[0]->push( $_[1]->( $_[0]->pop(2) ) ); $_[0]->top; }

sub _op_two { ($_[0]->_op_n(2, $_[1]))[-1] }
sub _op_n {
	$_[0]->push(my @r = $_[2]->( $_[0]->pop($_[1]) ));
	wantarray ? @r : $r[-1]
}

=item C<< twiddle >>

This reverses the position of the top two elements on the current stack.

=cut

sub twiddle  { (shift)->_op_two( sub { $_[1], $_[0] } ); }

=item C<< add >>

 x = pop; y = pop;
 push x + y;

This pops the top two values from the current stack, adds them, and pushes the
result.

=item C<< subtract >>

 x = pop; y = pop;
 push x - y;

This pops the top two values from the current stack, subtracts the second from
the first, and pushes the result.

=item C<< multiply >>

 x = pop; y = pop;
 push x * y;

This pops the top two values from the current stack, multiplies them, and
pushes the result.

=item C<< divide >>

 x = pop; y = pop;
 push x / y;

This pops the top two values from the current stack, divides the first by the
second, and pushes the result.

=cut

sub add      { (shift)->_op_two( sub { (shift) + (shift) } ); }
sub subtract { (shift)->_op_two( sub { (shift) - (shift) } ); }
sub multiply { (shift)->_op_two( sub { (shift) * (shift) } ); }
sub divide   { (shift)->_op_two( sub { (shift) / (shift) } ); }

=item C<< modulo >>

 x = pop; y = pop;
 push x % y;

This pops the top two values from the current stack, computes the first modulo
the second, and pushes the result.

=item C<< raise_to >>

 x = pop; y = pop;
 push x ** y;

This pops the top two values from the current stack, raises the first to the
power of the second, and pushes the result.

=item C<< root >>

 x = pop; y = pop;
 push x ** (1/y);

This pops the top two values from the current stack, finds the I<y>th root of
I<x>, and pushes the result.

=item C<< sqrt >>

This method pops the top value from the current stack and pushes its square
root.

=cut

sub modulo   { (shift)->_op_two( sub { (shift) % (shift) } ); }
sub raise_to { (shift)->_op_two( sub { (shift) **(shift) } ); }
sub root     { (shift)->_op_two( sub { (shift)**(1/(shift)) } ); }
sub sqrt     { my ($self) = @_; $self->push(2); $self->root; }

=item C<< quorem >>

=item C<< divmod >>

This method pops two values from the stack and divides them.  It pushes the
integer part of the quotient, and then the remainder.

=cut

sub _quorem  { my ($n,$m) = @_; (int($n/$m), $n % $m) }
sub quorem   { (shift)->_op_n(2, \&_quorem ); }
sub divmod   { (shift)->_op_n(2, \&_quorem ); }

=back

=head1 TODO

I'd like to write some user interfaces to this module, probably by porting
Math::RPN, writing a dc-alike, and possibly a simple Curses::UI interface.

I want to add BigInt and BigFloat support for better precision.

I'd like to make Math::Calculator pluggable, so that extra operations can be
added easily.

=head1 SEE ALSO

=over

=item * L<Math::RPN>

=item * L<Parse::RPN>

=back

=head1 AUTHORS

Ricardo SIGNES, E<lt>rjbs@cpan.orgE<gt>

Thanks, also, to Duan TOH.  I spent a few days giving him a crash course in
intermediate Perl and became interested in writing this class when I used it as
a simple example of how objects in Perl work.

=head1 COPYRIGHT

Math::Calculator is available under the same terms as Perl itself.

=cut

1;

