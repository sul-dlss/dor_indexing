# frozen_string_literal: true

require 'zeitwerk'

Zeitwerk::Loader.for_gem.setup

# Zeitwerk doesn't auto-load these dependencies
require 'active_support'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/string'
require 'cocina/models'
require 'dor/services/client'
require 'honeybadger'
require 'marc/vocab'

# Builds solr documents for indexing.
class DorIndexing
  # @return [Hash] the solr document
  def self.build(cocina_with_metadata:, workflow_client:, dor_services_client:, cocina_repository:)
    Honeybadger.context({ identifier: cocina_with_metadata.externalIdentifier })
    DorIndexing::Builders::DocumentBuilder.for(
      model: cocina_with_metadata,
      workflow_client:,
      dor_services_client:,
      cocina_repository:
    ).to_solr
  end
end
