# frozen_string_literal: true

class DorIndexing
  module Indexers
    # Indexes the object's release tags
    class ReleasableIndexer
      attr_reader :cocina, :parent_collections, :release_tags_finder

      def initialize(cocina:, parent_collections:, release_tags_finder:, **)
        @cocina = cocina
        @parent_collections = parent_collections
        @release_tags_finder = release_tags_finder
      end

      # @return [Hash] the partial solr document for releasable concerns
      def to_solr
        return {} if tags.blank?

        {
          'released_to_ssim' => tags.map(&:to).uniq,
          'released_to_searchworks_dttsi' => searchworks_release_date,
          'released_to_earthworks_dttsi' => earthworks_release_date
        }.compact
      end

      private

      def earthworks_release_date
        tags.find { |tag| tag.to == 'Earthworks' }&.date&.utc&.iso8601
      end

      def searchworks_release_date
        tags.find { |tag| tag.to == 'Searchworks' }&.date&.utc&.iso8601
      end

      # Item tags have precidence over collection tags, so if the collection is release=true
      # and the item is release=false, then it is not released
      def tags
        @tags ||= tags_from_collection.merge(tags_from_item).values.select(&:release)
      end

      def tags_from_collection
        parent_collections.each_with_object({}) do |collection, result|
          release_tags_finder
            .call(collection.externalIdentifier)
            .select { |tag| tag.what == 'self' }
            .group_by(&:to).map do |project, releases_for_project|
              result[project] = releases_for_project.max_by(&:date)
            end
        end
      end

      def tags_from_item
        release_tags_finder
          .call(cocina.externalIdentifier)
          .select { |tag| tag.what == 'self' }
          .group_by(&:to).transform_values do |releases_for_project|
            releases_for_project.max_by(&:date)
          end
      end
    end
  end
end
