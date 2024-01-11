# DorIndexing

DorIndexing is a Ruby gem that creates Solr documents from Cocina objects for the purposes of indexing. It was extracted from DOR Indexing App.

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
