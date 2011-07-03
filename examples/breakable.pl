# This example is a port of Breakable.h from the Box2D Testbed.
use strict;
use warnings;
use Box2D;
use SDL;
use SDL::Video;
use SDLx::App;

package Breakable;
use Moose;

use List::Util qw(max);

# Initial coordinates and size
has [qw( x y w h )] => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);

has world => (
    is       => 'ro',
    isa      => 'Box2D::b2World',
    required => 1,
);

has body1 => (
    is      => 'ro',
    isa     => 'Box2D::b2Body',
    lazy    => 1,
    builder => '_build_body1',
);

# Used after the break
has body2 => (
    is  => 'rw',
    isa => 'Box2D::b2Body',
);

has velocity => (
    is      => 'rw',
    isa     => 'Box2D::b2Vec2',
    default => sub { Box2D::b2Vec2->new( 0.0, 0.0 ) },
);

has angularVelocity => (
    is      => 'rw',
    isa     => 'Num',
    default => 0.0,
);

has shape1 => (
    is      => 'ro',
    isa     => 'Box2D::b2PolygonShape',
    lazy    => 1,
    builder => '_build_shape1',
);

has shape2 => (
    is      => 'ro',
    isa     => 'Box2D::b2PolygonShape',
    lazy    => 1,
    builder => '_build_shape2',
);

has piece1 => (
    is      => 'ro',
    isa     => 'Box2D::b2Fixture',
    lazy    => 1,
    builder => '_build_piece1',
);

has piece2 => (
    is      => 'rw',
    isa     => 'Box2D::b2Fixture',
    lazy    => 1,
    builder => '_build_piece2',
);

has [qw( broke break )] => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has listener => (
    is      => 'ro',
    isa     => 'Box2D::PerlContactListener',
    default => sub { Box2D::PerlContactListener->new() },
);

sub BUILD {
    my ($self) = @_;
    $self->listener->SetPostSolveSub( sub { $self->PostSolve(@_) } );
    $self->world->SetContactListener( $self->listener );
}

sub _build_body1 {
    my ($self) = @_;
    my $bodyDef = Box2D::b2BodyDef->new();
    $bodyDef->type(Box2D::b2_dynamicBody);
    $bodyDef->position->Set( $self->x, $self->y );
    $bodyDef->angle( rand(3.14) );
    my $body1 = $self->world->CreateBody($bodyDef);
    return $body1;
}

sub _build_shape1 {
    my ($self) = @_;
    my $shape1 = Box2D::b2PolygonShape->new();
    $shape1->SetAsBox(
        $self->w / 4.0,
        $self->h / 2.0,
        Box2D::b2Vec2->new( -$self->w / 4.0, 0.0 ), 0.0
    );
    return $shape1;
}

sub _build_shape2 {
    my ($self) = @_;
    my $shape2 = Box2D::b2PolygonShape->new();
    $shape2->SetAsBox(
        $self->w / 4.0,
        $self->h / 2.0,
        Box2D::b2Vec2->new( $self->w / 4.0, 0.0 ), 0.0
    );
    return $shape2;
}

sub _build_piece1 {
    my ($self) = @_;
    my $fixtureDef = Box2D::b2FixtureDef->new();
    $fixtureDef->shape( $self->shape1 );
    $fixtureDef->density(0.5);
    $fixtureDef->friction(0.5);
    $fixtureDef->restitution(0.5);
    return $self->body1->CreateFixtureDef($fixtureDef);
}

sub _build_piece2 {
    my ($self) = @_;
    my $fixtureDef = Box2D::b2FixtureDef->new();
    $fixtureDef->shape( $self->shape2 );
    $fixtureDef->density(0.5);
    $fixtureDef->friction(0.5);
    $fixtureDef->restitution(0.5);
    return $self->body1->CreateFixtureDef($fixtureDef);
}

sub PostSolve {
    my ( $self, $contact, $impulse ) = @_;

    return if $self->broke;

    my $maxImpulse = max( map { $impulse->normalImpulses($_) }
            ( 0 .. $contact->GetManifold()->pointCount() - 1 ) );

    $self->break(1) if $maxImpulse > 1.0;
}

sub Break {
    my ($self) = @_;

    my $body1  = $self->body1;
    my $center = $body1->GetWorldCenter();

    $body1->DestroyFixture( $self->piece2 );

    my $bodyDef = Box2D::b2BodyDef->new();
    $bodyDef->type(Box2D::b2_dynamicBody);
    my $p = $body1->GetPosition();
    $bodyDef->position->Set( $p->x, $p->y );
    $bodyDef->angle( $body1->GetAngle() );

    my $fixtureDef = Box2D::b2FixtureDef->new();
    $fixtureDef->shape( $self->shape2 );
    $fixtureDef->density(1.0);
    $fixtureDef->restitution(0.5);
    my $body2 = $self->world->CreateBody($bodyDef);
    $self->piece2( $body2->CreateFixtureDef($fixtureDef) );

    my $center1 = $body1->GetWorldCenter();
    my $center2 = $body2->GetWorldCenter();

    # b2Cross has not been implemented, the code below emulates it's behavior
    # velocityN = velocity + b2Cross( angularVelocity, centerN - center )
    my $velocity1 = Box2D::b2Vec2->new(
        $self->velocity->x
            - $self->angularVelocity * ( $center1->y - $center->y ),
        $self->velocity->y
            + $self->angularVelocity * ( $center1->x - $center->x )
    );
    my $velocity2 = Box2D::b2Vec2->new(
        $self->velocity->x
            - $self->angularVelocity * ( $center2->y - $center->y ),
        $self->velocity->y
            + $self->angularVelocity * ( $center2->x - $center->x )
    );

    $body1->SetAngularVelocity( $self->angularVelocity );
    $body1->SetLinearVelocity($velocity1);

    $body2->SetAngularVelocity( $self->angularVelocity );
    $body2->SetLinearVelocity($velocity2);

    $self->body2($body2);
}

sub Step {
    my ($self) = @_;

    if ( $self->break ) {
        $self->Break();
        $self->broke(1);
        $self->break(0);
    }

    if ( !$self->broke ) {
        $self->velocity( $self->body1->GetLinearVelocity() );
        $self->angularVelocity( $self->body1->GetAngularVelocity() );
    }
}

no Moose;

package main;

# screen dimensions in pixels
my ( $width, $height ) = ( 300, 300 );

# pixels per meter
my $ppm = 30;

# meters per pixel
my $mpp = 1.0 / $ppm;

# frames per second
my $fps      = 60.0;
my $timestep = 1.0 / $fps;

# velocity iterations
my $vIters = 10;

# position iterations
my $pIters = 10;

my $gravity = Box2D::b2Vec2->new( 0, 9.8 );
my $world = Box2D::b2World->new( $gravity, 1 );

my $ground = make_ground();

my @breakables;
push @breakables, make_breakable( $width / 2.0, 40 );

my $app = SDLx::App->new(
    width  => $width,
    height => $height,
    dt     => $timestep,
    min_t  => $timestep / 2,
    flags  => SDL_DOUBLEBUF | SDL_HWSURFACE,
    eoq    => 1,
);

$app->add_show_handler(
    sub {
        $_->Step() foreach @breakables;
        $world->Step( $timestep, $vIters, $pIters );
        $world->ClearForces();

        $app->draw_rect( undef, 0x000000FF );
        draw_breakable( $app, $_ ) foreach @breakables;
        $app->update();
    }
);

$app->run();

# screen to world
sub s2w { return $_[0] * $mpp }

# world to screen
sub w2s { return $_[0] * $ppm }

sub make_breakable {
    my ( $x, $y ) = @_;

    my $breakable = Breakable->new(
        world => $world,
        x     => s2w($x),
        y     => s2w($y),
        w     => s2w(40),
        h     => s2w(40),
    );
    $breakable->piece1;
    $breakable->piece2;

    return $breakable;
}

sub make_ground {
    my $bodyDef = Box2D::b2BodyDef->new();
    my $ground  = $world->CreateBody($bodyDef);
    my $shape   = Box2D::b2PolygonShape->new();

    $shape->SetAsEdge(
        Box2D::b2Vec2->new( 0.0,         s2w($height) ),
        Box2D::b2Vec2->new( s2w($width), s2w($height) ),
    );
    $ground->CreateFixture( $shape, 0.0 );

    return $ground;
}

sub draw_breakable {
    my ( $surface, $breakable ) = @_;

    my @parts = (
        [ $breakable->body1, $breakable->shape1 ],
        [   $breakable->broke ? $breakable->body2 : $breakable->body1,
            $breakable->shape2
        ]
    );

    foreach my $part (@parts) {
        my ( $body, $shape ) = @$part;

        my @verts = map { [ w2s( $_->x ), w2s( $_->y ) ] }
            map { $body->GetWorldPoint( $shape->GetVertex($_) ) }
            ( 0 .. $shape->GetVertexCount() - 1 );

        $surface->draw_polygon_filled( \@verts, 0xFFFFFFFF );
    }
}
