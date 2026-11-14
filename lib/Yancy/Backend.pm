package Yancy::Backend;
our $VERSION = '1.089';
# ABSTRACT: Interface to a data source

=head1 SYNOPSIS

    my $be = Yancy::Backend->new( $url );

    $result = $be->list( $schema, $where, $options );
    $item = $be->get( $schema, $id );
    $be->set( $schema, $id, $item );
    $be->delete( $schema, $id );
    $id = $be->create( $schema, $item );

=head1 DESCRIPTION

A C<Yancy::Backend> handles talking to the data source and presenting an API
for L<Yancy::Model>. Backends are specifically for creating libraries to talk
to data sources. For applications, use L<Yancy::Model>.

=head1 EXTENDING

To create your own Yancy::Backend for a new data source, inherit
from this class and provide the standard six interface methods: L</get>,
L</create>, L</set>, L</list>, L</delete>, and L</read_schema>.

There are roles to aid backend development:

=over

=item * L<Yancy::Backend::Role::DBI> provides some methods based on
L<DBI>

=item * L<Yancy::Backend::Role::Sync> provides promise-based API methods
for data sources which are synchronous-only.

=back

=cut

use Mojo::Base '-base';
use Scalar::Util qw( blessed );
use Yancy::Util qw( is_type is_format );
use Mojo::JSON qw( encode_json );

has schema => sub { {} };

=head1 METHODS

=head2 new

    my $url = 'memory://custom_string';
    my $be = Yancy::Backend::Memory->new( $url );

Create a new backend object. C<$url> is a string that begins with the
backend name followed by a colon. Everything else in the URL is for the
backend to use to describe how to connect to the underlying data source and
any options for the backend object itself.

The backend name will be run through C<ucfirst> before being looked up
in C<Yancy::Backend::>. For example, C<mysql://...> will use the
L<Yancy::Backend::Mysql> module.

=cut

sub new {
    my ( $class, $driver ) = @_;
    if ( $class eq __PACKAGE__ ) {
        return load_backend( $driver );
    }
    return $class->SUPER::new( driver => $driver );
}

=head2 list

Fetch a list of items from a schema. C<$schema> is the schema name. C<$where>
is a L<SQL::Abstract where structure|SQL::Abstract/WHERE CLAUSES>.

C<%opt> is a list of name/value pairs with the following keys:

=over

=item * limit - The number of items to return

=item * offset - The number of items to skip

=item * order_by - A L<SQL::Abstract order by clause|SQL::Abstract/ORDER BY CLAUSES>

=item * join - Join one or more tables using a C<x-foreign-key> field.
This can be the name of a foreign key field on this schema, or the name
of a table with a foreign key field that refers to this schema. Join
multiple tables at the same time by passing an arrayref of joins. Fields
in joined tables can be queried by prefixing the join name to the field,
separated by a dot.

=back

Returns a hashref with two keys:

=over

=item items

An array reference of hash references of item data

=item total

The total count of items that would be returned without C<limit> or
C<offset>.

=back

=cut

sub list { ... }

=head2 list_p

Fetch a list of items asynchronously using promises. Returns a promise that
resolves to a hashref with C<items> and C<total> keys. See L</list> for
arguments and return values.

=cut

sub list_p { ... }

=head2 get

Get a single item. C<$schema> is the schema name. C<$id> is the
ID of the item to get: Either a string for a single key field, or a
hash reference for a composite key. Returns a hashref of item data.

C<%opts> is a list of name/value pairs of options with the following
names:

=over

=item join

Join one or more tables using a C<x-foreign-key> field. This should be
the name of the schema to join, either by a foreign key on this table,
or a foreign key on the joined table. Join multiple tables at the same
time by passing an arrayref of joins.

=cut

sub get { ... }

=head2 get_p

Get a single item asynchronously using promises. Returns a promise that
resolves to the item. See L</get> for arguments and return values.

=cut

sub get_p { ... }

=head2 set

Update an item. C<$schema> is the schema name. C<$id> is the ID of the
item to update: Either a string for a single key field, or a hash
reference for a composite key. C<$item> is the item's data to set.
Returns a boolean that is true if a row with the given ID was found and
updated, false otherwise.

Currently the values of the data cannot be references, only simple
scalars or JSON booleans.

=cut

sub set { ... }

=head2 set_p

Update a single item asynchronously using promises. Returns a promise
that resolves to a boolean indicating if the row was updated. See
L</set> for arguments and return values.

=cut

sub set_p { ... }

=head2 create

Create a new item. C<$schema> is the schema name.  C<$item> is
the item's data. Returns the ID of the row created suitable to be passed
in to C<the get() method|/get>.

Currently the values of the data cannot be references, only simple
scalars or JSON booleans.

=cut

sub create { ... }

=head2 create_p

Create a new item asynchronously using promises. Returns a promise that
resolves to the ID of the newly-created item. See L</create> for
arguments and return values.

=cut

sub create_p { ... }

=head2 delete

Delete an item. C<$schema> is the schema name. C<$id> is the ID of the
item to delete: Either a string for a single key field, or a hash
reference for a composite key. Returns a boolean that is true if a row
with the given ID was found and deleted. False otherwise.

=cut

sub delete { ... }

=head2 delete_p

Delete an item asynchronously using promises. Returns a promise that
resolves to a boolean indicating if the row was deleted. See L</delete>
for arguments and return values.

=cut

sub delete_p { ... }

=head2 query

Run a raw query on the backend. Each backend may have its own arguments.
Returns a list of hash references of data.

=cut

sub query { ... }

=head2 query_p

Run a raw query on the backend. Each backend may have its own arguments.
Returns a promise that resolves into a list of hash references of data.

=cut

sub query_p { ... }

=head2 read_schema

Read the schema from the data source tables. Returns a JSON Schema
ready to be merged into the user's configuration. Can be restricted
to only a single table.

=cut

sub read_schema { ... }

=head1 INTERNAL METHODS

These methods are documented for use in subclasses and should not need
to be called externally.

=head2 supports

Returns true if the backend supports a given feature. Returns false for now.
In the future, features like 'json' will be detectable.

=cut

sub supports { 0 }

=head2 ignore_table

Returns true if the given table should be ignored when doing L</read_schema>.
By default, backends will ignore tables used by:

=over

=item * L<Minion> backends (L<Minion::Backend::mysql>, L<Minion::Backend::Pg>, L<Minion::Backend::SQLite>)
=item * L<DBIx::Class::Schema::Versioned>
=item * Mojo DB migrations (L<Mojo::mysql::Migrations>, L<Mojo::Pg::Migrations>, L<Mojo::SQLite::Migrations>)
=item * L<Mojo::mysql::PubSub>

=back

=cut

our %IGNORE_TABLE = (
    mojo_migrations => 1,
    minion_jobs => 1,
    minion_workers => 1,
    minion_locks => 1,
    minion_workers_inbox => 1,
    minion_jobs_depends => 1,
    mojo_pubsub_subscribe => 1,
    mojo_pubsub_notify => 1,
    dbix_class_schema_versions => 1,
);
sub ignore_table {
    return $IGNORE_TABLE{ $_[1] } // 0;
}

=head2 normalize

This method normalizes data to and from the data source.

=cut

sub normalize {
    my ( $self, $schema_name, $data ) = @_;
    return undef if !$data;
    my $schema = $self->schema->{ $schema_name };
    my %props = %{ $schema->{properties} };
    my %replace;
    for my $key ( keys %$data ) {
        next if !defined $data->{ $key }; # leave nulls alone
        my $prop = $props{ $key } || next;
        my ( $type, $format ) = @{ $prop }{qw( type format )};
        if ( is_type( $type, 'boolean' ) ) {
            # Boolean: true (1, "true"), false (0, "false")
            $replace{ $key }
                = $data->{ $key } && $data->{ $key } !~ /^false$/i
                ? 1 : 0;
        }
        elsif ( is_type( $type, 'string' ) && is_format( $format, 'date-time' ) ) {
            if ( !$data->{ $key } ) {
                $replace{ $key } = undef;
            }
            elsif ( $data->{ $key } eq 'now' ) {
                $replace{ $key } = \'CURRENT_TIMESTAMP';
            }
            else {
                $replace{ $key } = $data->{ $key };
                $replace{ $key } =~ s/T/ /;
            }
        }
    }

    my $params = +{ %$data, %replace };
    return $params;
}

=head2 id_field

Get the ID field for the given schema. Defaults to C<id>.
=cut

sub id_field {
    my ( $self, $schema ) = @_;
    return $self->schema->{ $schema }{ 'x-id-field' } || 'id';
}

=head2 id_where

Get the query structure for the ID field of the given schema with the
given ID value.

=cut

sub id_where {
    my ( $self, $schema_name, $id ) = @_;
    my %where;
    my $id_field = $self->id_field( $schema_name );
    if ( ref $id_field eq 'ARRAY' ) {
        for my $field ( @$id_field ) {
            next unless exists $id->{ $field };
            $where{ $field } = $id->{ $field };
        }
        die "Missing composite ID parts" if @$id_field > keys %where;
    }
    else {
        $where{ $id_field } = $id;
    }
    return %where;
}

1;
