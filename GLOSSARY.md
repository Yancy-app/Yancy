# Yancy

## Overview

Yancy is a Content Management System written in Perl using the Mojolicious web framework. It follows the Model View Controller (MVC) pattern, featuring a model layer, controllers, and an editor for basic model data editing.

## Glossary

### Yancy

A Perl-based Content Management System built with the Mojolicious web framework, following the Model View Controller (MVC) pattern.

### Model Layer (Yancy::Model)

The foundational layer for all data structure management. `Yancy::Model` is the base class that builds a JSON Schema representation of the entire model. Models are organized into `Yancy::Model::Schema` (collections) and `Yancy::Model::Item` (individual records).

*   **Schema:** A collection of items representing a relational database table.
*   **Item:** An individual data record representing a database row.
*   **JSON Schema:** The output of the Model layer, used to describe the model, validate incoming data, and build forms. It includes Yancy extension fields (`x-`) for custom requirements.

### Controller

Modules responsible for handling user requests, processing data within the Model Layer, and generating responses.

### Editor

The user interface component that combines `Yancy::Model` and `Yancy::Content` to provide a content management interface. It consists of two sections: "Website" (for editing content within an iframe) and "Database" (for direct database data editing).

### MVC

The Model View Controller pattern that Mojolicious is designed for, structuring the application into distinct Model, View, and Controller responsibilities.