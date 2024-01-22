[![Gem Version](https://badge.fury.io/rb/dor_indexing.svg)](https://badge.fury.io/rb/dor_indexing)
[![CircleCI](https://circleci.com/gh/sul-dlss/dor_indexing.svg?style=svg)](https://circleci.com/gh/sul-dlss/dor_indexing)
[![Test Coverage](https://api.codeclimate.com/v1/badges/debefc8907cf263f45e9/test_coverage)](https://codeclimate.com/github/sul-dlss/dor_indexing/test_coverage)

# DorIndexing

DorIndexing is a Ruby gem that creates Solr documents from Cocina objects for the purposes of indexing. It was extracted from DOR Indexing App.

## Motivation

In our previous architecture, rolling indexing was performed on the Dor Indexing App server. This was inefficient and slow, as it required API calls to Dor Services App to retrieve Cocina items.

Gemifying the creation of Solr documents allows changing the architecture such that rolling indexing is performed on the Dor Services App server. This allows the more efficient retrieval of Cocina items via direct ActiveRecord db access.

Further, it allows other indexing (e.g., via RabbitMQ messages) to continue on the Dor Indexing App server.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add dor_indexing

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install dor_indexing

## Usage

DorIndexing that a configured Workflow Client and a Cocina Repository be injected.

The Cocina Repository provides methods for finding Cocina objects and administrative tags. One possible implementation of a Cocina Repository would be to use DOR Services Client.

```ruby
require 'dor_indexing'

doc = DorIndexing.build(cocina_with_metadata:, workflow_client:, cocina_repository:)
```
