# frozen_string_literal: true

class DorIndexing
  module Builders
    # Builds solr document for indexing.
    class DocumentBuilder
      ADMIN_POLICY_INDEXER = DorIndexing::Indexers::CompositeIndexer.new(
        DorIndexing::Indexers::AdministrativeTagIndexer,
        DorIndexing::Indexers::BasicIndexer,
        DorIndexing::Indexers::RoleMetadataIndexer,
        DorIndexing::Indexers::DefaultObjectRightsIndexer,
        DorIndexing::Indexers::IdentityMetadataIndexer,
        DorIndexing::Indexers::DescriptiveMetadataIndexer,
        DorIndexing::Indexers::IdentifiableIndexer,
        DorIndexing::Indexers::WorkflowsIndexer
      )

      COLLECTION_INDEXER = DorIndexing::Indexers::CompositeIndexer.new(
        DorIndexing::Indexers::AdministrativeTagIndexer,
        DorIndexing::Indexers::BasicIndexer,
        DorIndexing::Indexers::RightsMetadataIndexer,
        DorIndexing::Indexers::IdentityMetadataIndexer,
        DorIndexing::Indexers::DescriptiveMetadataIndexer,
        DorIndexing::Indexers::IdentifiableIndexer,
        DorIndexing::Indexers::ReleasableIndexer,
        DorIndexing::Indexers::WorkflowsIndexer
      )

      ITEM_INDEXER = DorIndexing::Indexers::CompositeIndexer.new(
        DorIndexing::Indexers::AdministrativeTagIndexer,
        DorIndexing::Indexers::BasicIndexer,
        DorIndexing::Indexers::RightsMetadataIndexer,
        DorIndexing::Indexers::IdentityMetadataIndexer,
        DorIndexing::Indexers::DescriptiveMetadataIndexer,
        DorIndexing::Indexers::EmbargoMetadataIndexer,
        DorIndexing::Indexers::ObjectFilesIndexer,
        DorIndexing::Indexers::IdentifiableIndexer,
        DorIndexing::Indexers::CollectionTitleIndexer,
        DorIndexing::Indexers::ReleasableIndexer,
        DorIndexing::Indexers::WorkflowsIndexer
      )

      INDEXERS = {
        Cocina::Models::ObjectType.agreement => ITEM_INDEXER, # Agreement uses same indexer as item
        Cocina::Models::ObjectType.admin_policy => ADMIN_POLICY_INDEXER,
        Cocina::Models::ObjectType.collection => COLLECTION_INDEXER
      }.freeze

      @@parent_collections = {} # rubocop:disable Style/ClassVars

      def self.for(...)
        new(...).for
      end

      def self.reset_parent_collections
        @@parent_collections = {} # rubocop:disable Style/ClassVars
      end

      def initialize(model:, workflow_client:, cocina_finder:, administrative_tags_finder:, release_tags_finder:)
        @model = model
        @workflow_client = workflow_client
        @cocina_finder = cocina_finder
        @administrative_tags_finder = administrative_tags_finder
        @release_tags_finder = release_tags_finder
      end

      # @param [Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata,Cocina::Model::AdminPolicyWithMetadata] model
      def for
        indexer_for_type(model.type).new(id:,
                                         cocina: model,
                                         parent_collections:,
                                         administrative_tags:,
                                         workflow_client:,
                                         cocina_finder:,
                                         administrative_tags_finder:,
                                         release_tags_finder:)
      end

      private

      attr_reader :model, :workflow_client, :cocina_finder, :administrative_tags_finder, :release_tags_finder

      def id
        model.externalIdentifier
      end

      def indexer_for_type(type)
        INDEXERS.fetch(type, ITEM_INDEXER)
      end

      def parent_collections
        return [] unless model.dro?

        Array(model.structural&.isMemberOf).filter_map do |rel_druid|
          @@parent_collections[rel_druid] ||= cocina_finder.call(rel_druid)
        rescue DorIndexing::RepositoryError
          Honeybadger.notify("Bad association found on #{model.externalIdentifier}. #{rel_druid} could not be found")
          # This may happen if the referenced Collection does not exist (bad data)
          nil
        end
      end

      def administrative_tags
        administrative_tags_finder.call(id)
      rescue DorIndexing::RepositoryError
        []
      end
    end
  end
end
