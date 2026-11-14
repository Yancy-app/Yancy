package Yancy::Plugin::Storage;
our $VERSION = '1.089';
# ABSTRACT: Simple default for a website using Storage

=head1 SYNOPSIS

  $app->plugin('Yancy::Storage' => {
    storage => $app->home->child('public/uploads'),
    route => '/storage',
  });

  # In a template
  %= image url_for( 'storage', { id => $storage_id } )

=head1 DESCRIPTION

This plugin sets up a L<Yancy::Storage> object and adds named routes for
viewing files in storage. The storage object is made available by the
L</storage> helper and will be automatically found by L<Yancy::Editor>.

=cut

use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Yancy::Storage;

has storage => ;

sub register($self, $app, $config) {
  # XXX: Create storage from $config->{storage}

  $app->helper( storage => sub { $self->storage });
  # XXX: Set up routes under 'route'
}

1;
