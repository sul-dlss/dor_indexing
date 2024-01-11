# frozen_string_literal: true

class DorIndexing
  module Builders
    # Finds the place to index from publication events
    class EventPlaceBuilder
      # @param [Cocina::Models::Event] event
      # @return [String] the place value for Solr
      def self.build(event)
        new(event).build
      end

      def initialize(event)
        @event = event
      end

      def build
        return unless event

        primary_location || location_from(flat_locations)
      end

      private

      attr_reader :event

      def primary_location
        location_from([flat_locations.find { |location| location.status == 'primary' }].compact)
      end

      def location_from(locations)
        return if locations.empty?

        value_locations_for(locations) ||
          marccountry_text_for(locations) ||
          marccountry_code_for(locations)
      end

      # rubocop:disable Metrics/AbcSize
      def flat_locations
        @flat_locations ||= begin
          locations = if event.parallelEvent.present?
                        event.parallelEvent.flat_map { |parallel_event| Array(parallel_event.location) }
                      else
                        Array(event.location)
                      end
          locations.flat_map { |location| location.parallelValue.presence || location.structuredValue.presence || location }
        end
      end
      # rubocop:enable Metrics/AbcSize

      def marccountry_text_for(locations)
        locations.find { |location| marc_country?(location) && location.value }&.value
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def marccountry_code_for(locations)
        DorIndexing::MarcCountry.from_code(locations.find { |location| marc_country?(location) && location.code }&.code) ||
          DorIndexing::MarcCountry.from_uri(locations.find { |location| location.uri&.start_with?(DorIndexing::MarcCountry::MARC_COUNTRY_URI) }&.uri)
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def value_locations_for(locations)
        locations.select { |location| location.value && !marc_country?(location) }.map(&:value).join(' : ').presence
      end

      def marc_country?(location)
        location.source&.code == DorIndexing::MarcCountry::MARC_COUNTRY_CODE ||
          location.source&.uri == DorIndexing::MarcCountry::MARC_COUNTRY_URI
      end
    end
  end
end
