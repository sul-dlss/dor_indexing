[![CircleCI](https://dl.circleci.com/status-badge/img/gh/sul-dlss/dor_indexing/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/sul-dlss/dor_indexing/tree/main)
[![Test Coverage](https://api.codeclimate.com/v1/badges/debefc8907cf263f45e9/test_coverage)](https://codeclimate.com/github/sul-dlss/dor_indexing/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/debefc8907cf263f45e9/maintainability)](https://codeclimate.com/github/sul-dlss/dor_indexing/maintainability)
[![Gem Version](https://badge.fury.io/rb/dor_indexing.svg)](https://badge.fury.io/rb/dor_indexing)

# DorIndexing

DorIndexing is a Ruby gem to create Solr documents from Cocina objects for the purposes of indexing. It was extracted from DOR Indexing App.

## Motivation

In our previous architecture, rolling (re)indexing was performed on the Dor Indexing App server. This was inefficient and slow, as it required API calls to Dor Services App to retrieve Cocina items.

We wanted a way to move the rolling (re)indexing to be performed on the Dor Services App server, while leaving the Dor Indexing App as is for all other indexing functionality.  Creating a gem and using it in both DSA and DIA is the best way to ensure the indexing code remains in sync for the two applicaitons.

Running the rolling (re)indexing on a Dor Services App server allows more efficient retrieval of Cocina items via direct ActiveRecord db access.

Meanwhile, we keep all other indexing (e.g., that triggered via RabbitMQ messages) to continue on the Dor Indexing App server.

If we move all the indexing to DSA, it may be less useful to keep this code in a gem.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add dor_indexing

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install dor_indexing

## Usage

To use this gem, you will need a configured
- Dor Workflow Client (to get workflow information for an SDR object)
- Dor Services Client (to get the cocina data and the administrative tags, etc. for an SDR object)

Various configuration settings will be needed in the application config/settings.yml files for these clients.

```ruby
require 'dor_indexing'

doc = DorIndexing.build(cocina_with_metadata:, workflow_client:, cocina_repository:)
```
