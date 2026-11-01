# Yancy Content Management System

Yancy is a Content Management System written in Perl using the Mojolicious web
framework. Yancy uses the Model View Controller (MVC) pattern that Mojolicious
is designed for. Yancy itself provides the model layer, controllers that work
on that model layer, and includes an editor that allows basic editing of model
data.

See the CONTRIBUTING.md file for a basic introduction to developing on the
project itself.

## Model

The model base class is Yancy::Model. Models are organized into
Yancy::Model::Schema (schemas) and Yancy::Model::Item (items). Schemas are
collections of items, and can represent a relational database table. Items are
individual data records and can represent database rows. The model class is
generic enough to handle representing things other than databases, like NoSQL
databases or data from external APIs.

The model class builds a JSON Schema representation of the entire model. This
JSON Schema is used to describe the model, validate incoming data, and build
forms. The JSON Schema contains Yancy extension fields beginning with `x-` that
further describe the schema for Yancy's needs.

Model classes can contain SQL migrations in the `__DATA__` section to
automatically build a database schema when they are loaded. This is the recommended
way to automatically set up a database for a Yancy model.

## Editor

The editor combines Yancy::Model and Yancy::Content to create a content
management interface for users. The main section ("Website") allows a user to
edit their website as they navigate it in an iframe. The secondary section
("Database") allows editing database data directly.
