package Box2D::b2RayCastCallback;
use strict;
use warnings;
use Box2D;
use Carp;

sub new {
    my ($class) = @_;

    my $self = bless {}, $class;

    $self->{_callback}
        = Box2D::PerlRayCastCallback->new( sub { $self->ReportFixture(@_) } );

    return $self;
}

sub ReportFixture {
    croak 'You must override Box2D::b2RayCastCallback::ReportFixture';
}

sub _getCallback { $_[0]->{_callback} }

1;

=head1 NAME

Box2D::b2RayCastCallback - Callback class for ray casts

=head1 SYNOPSIS

    package My::RayCastCallback;
    use Box2D;

    use base qw(Box2D::b2RayCastCallback);

    sub ReportFixture {
        my ( $self, $fixture, $point, $normal, $fraction ) = @_;

        # Do something
    }

    1;

=head1 DESCRIPTION

Callback class for ray casts. See L<Box2D::b2World/RayCast>.

=head1 METHODS

=head2 new

Creates and returns a new C<Box2D::b2RayCastCallback>. This is an
inheritance friendly sub so you're free to leave it as default. Remember
to call super in your own code, don't forget to call this!

=head2 ReportFixture( $fixture, $point, $normal, $fraction )

Called for each fixture found in the query. You control how the ray cast
proceeds by returning a float.

Override this method in your subclass.

Parameters:

=over 4

=item C<Box2D::b2Fixture $fixture> the fixture hit by the ray

=item C<Box2D::b2Vec2 $point> the point of initial intersection

=item C<Box2D::b2Vec2 $normal> the normal vector at the point of intersection

=item C<float32 $fraction> the fraction of the distance to the point of
intersection

=back

Returns:

=over 4

=item C<-1> to ignore the fixture and continue

=item C<0> to terminate the ray cast

=item C<$fraction> to clip the ray for closest hit

=item C<1> don't clip the ray and continue

=back

=head1 BUGS

See L<Box2D/BUGS>

=head1 AUTHORS

See L<Box2D/AUTHORS>

=head1 COPYRIGHT & LICENSE

See L<Box2D/"COPYRIGHT & LICENSE">

=head1 SEE ALSO

=over 4

=item L<Box2D>

=item L<Box2D::b2World>

=back

=cut
