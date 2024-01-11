# frozen_string_literal: true

class DorIndexing
  module Indexers
    # Indexes the identifiable concerns
    class IdentifiableIndexer
      attr_reader :cocina, :cocina_repository

      CURRENT_CATALOG_TYPE = 'folio'

      def initialize(cocina:, cocina_repository:, **)
        @cocina = cocina
        @cocina_repository = cocina_repository
      end

      ## Module-level variables, shared between ALL mixin includers (and ALL *their* includers/extenders)!
      ## used for caching found values
      @@apo_hash = {} # rubocop:disable Style/ClassVars

      # @return [Hash] the partial solr document for identifiable concerns
      def to_solr
        {}.tap do |solr_doc|
          add_apo_titles(solr_doc, cocina.administrative.hasAdminPolicy)

          solr_doc['metadata_source_ssim'] = identity_metadata_sources unless cocina.is_a? Cocina::Models::AdminPolicyWithMetadata
          # This used to be added to the index by https://github.com/sul-dlss/dor-services/commit/11b80d249d19326ef591411ffeb634900e75c2c3
          # and was called dc_identifier_druid_tesim
          # It is used to search based on druid.
          solr_doc['objectId_tesim'] = [cocina.externalIdentifier, cocina.externalIdentifier.delete_prefix('druid:')]
        end
      end

      # @return [Array<String>] calculated values for Solr index
      def identity_metadata_sources
        return ['DOR'] if !cocina.identification.respond_to?(:catalogLinks) || distinct_current_catalog_types.empty?

        distinct_current_catalog_types.map(&:capitalize)
      end

      # Clears out the cache of items. Used primarily in testing.
      def self.reset_cache!
        @@apo_hash = {} # rubocop:disable Style/ClassVars
      end

      private

      def distinct_current_catalog_types
        # Filter out e.g. "previous symphony", "previous folio"
        @distinct_current_catalog_types ||=
          cocina.identification
                .catalogLinks
                .map(&:catalog)
                .uniq
                .sort
                .select { |catalog_type| catalog_type == CURRENT_CATALOG_TYPE }
      end

      # @param [Hash] solr_doc
      # @param [String] admin_policy_id
      def add_apo_titles(solr_doc, admin_policy_id)
        row = populate_cache(admin_policy_id)
        title = row['related_obj_title']
        if row['is_from_hydrus']
          ::Solrizer.insert_field(solr_doc, 'hydrus_apo_title', title, :symbol)
        else
          ::Solrizer.insert_field(solr_doc, 'nonhydrus_apo_title', title, :symbol)
        end
        ::Solrizer.insert_field(solr_doc, 'apo_title', title, :symbol)
      end

      # populate cache if necessary
      def populate_cache(rel_druid)
        @@apo_hash[rel_druid] ||= begin
          related_obj = cocina_repository.find(rel_druid)
          # APOs don't have projects, and since Hydrus is set to be retired, I don't want to
          # add the cocina property. Just check the tags service instead.
          is_from_hydrus = hydrus_tag?(rel_druid)
          title = Cocina::Models::Builders::TitleBuilder.build(related_obj.description.title)
          { 'related_obj_title' => title, 'is_from_hydrus' => is_from_hydrus }
        rescue CocinaRepository::RepositoryError
          Honeybadger.notify("Bad association found on #{cocina.externalIdentifier}. #{rel_druid} could not be found")
          # This may happen if the given APO or Collection does not exist (bad data)
          { 'related_obj_title' => rel_druid, 'is_from_hydrus' => false }
        end
      end

      def hydrus_tag?(id)
        cocina_repository.administrative_tags(id).include?('Project : Hydrus')
      end
    end
  end
end
