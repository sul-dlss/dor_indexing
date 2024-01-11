# frozen_string_literal: true

class DorIndexing
  # Interface for retrieving Cocina objects.
  # In DSA, the concrete implementation backs this with CocinaObjectStore.
  # In DIA, the concrete implementation backs this with Dor Services Client.
  class CocinaRepository
    class RepositoryError < StandardError; end

    # @param [String] druid
    # @return [Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata,Cocina::Models::AdminPolicyWithMetadata]
    # @raise [RepositoryError] if the object is not found or other error occurs
    def find(druid)
      raise NotImplementedError
    end

    # @param [String] druid
    # @return [Array<String>] administrative tags
    # @raise [RepositoryError] if the object is not found or other error occurs
    def administrative_tags(druid)
      raise NotImplementedError
    end
  end
end
