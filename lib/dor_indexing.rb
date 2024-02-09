# frozen_string_literal: true

require 'zeitwerk'
require 'stanford-mods'
require 'cocina/models'
require 'marc/vocab'
require 'honeybadger'

Zeitwerk::Loader.for_gem.setup

# Builds solr documents for indexing.
class DorIndexing
  # @return [Hash] the solr document
  def self.build(cocina_with_metadata:, workflow_client:, cocina_repository:)
    Honeybadger.context({ identifier: cocina_with_metadata.externalIdentifier })
    DorIndexing::Builders::DocumentBuilder.for(model: cocina_with_metadata, workflow_client:, cocina_repository:).to_solr
  end
end
