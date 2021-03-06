use strict;
use warnings;
use Box2D;
use Test::More;

my $vec = Box2D::b2Vec2->new( 0, -10 );
my $world = Box2D::b2World->new( $vec, 1 );

my $body_def = Box2D::b2BodyDef->new();

$body_def->position->Set( 0.0, -10.0 );

my $groundBody = $world->CreateBody($body_def);

my $groundBox = Box2D::b2PolygonShape->new();

$groundBox->SetAsBox( 50.0, 10.0 );

$groundBody->CreateFixture( $groundBox, 0.0 );

my $bodyDef = Box2D::b2BodyDef->new();
$bodyDef->type(Box2D::b2_dynamicBody);
is( $bodyDef->type(), 2, "returning enum" );
$bodyDef->position->Set( 0.0, 4.0 );

my $body = $world->CreateBody($bodyDef);

pass("Create body for world ");

my $dynamicCircle = Box2D::b2CircleShape->new();
my $radius = 1.0;
$dynamicCircle->m_radius($radius);
is ( $dynamicCircle->m_radius(), $radius, "m_radius" );

pass("Create circle");

my $fixtureDef = Box2D::b2FixtureDef->new();
$fixtureDef->shape($dynamicCircle);
$fixtureDef->density(1.0);
$fixtureDef->friction(0.3);

$body->CreateFixtureDef($fixtureDef);

pass("Create fixture Def");

my $timeStep           = 1.0 / 60.0;
my $velocityIterations = 6;
my $positionIterations = 2;

foreach ( 0 .. 60 ) {

    $world->Step( $timeStep, $velocityIterations, $positionIterations );
    $world->ClearForces();

    my $position = $body->GetPosition();
    my $angle    = $body->GetAngle();
    #warn( "Position " . $position->x() . ", " . $position->y() . "\n" );
    #warn( "Angle " . $angle . "\n" );
}

pass("Run step and clear forces");

pass("Made stuff and survived");

$world->DestroyBody($body);
$body = undef;

pass("Destroyed the body");

done_testing;
