# frozen_string_literal: true

class DorIndexing
  # Error raised retrieving Cocina objects, administrative tags, or release tags
  # In DSA, the concrete implementation backs this with CocinaObjectStore.
  # In DIA, the concrete implementation backs this with Dor Services Client.
  class RepositoryError < StandardError; end
end
