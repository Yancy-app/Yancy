package Yancy::Content::Schema::Blocks;
use Mojo::Base 'Yancy::Model::Schema', -signatures;
use Mojo::JSON qw( true false );

sub json_schema( $self ) {
  my $schema = $self->SUPER::json_schema;

  # We only manipulate blocks through a special UI, not the standard database
  # UI
  $schema->{'x-hidden'} = true;

  return $schema;
}

1;
