# frozen_string_literal: true

RSpec.describe DorIndexing do
  describe '.build' do
    let(:doc) { described_class.build(cocina_with_metadata:, workflow_client:, dor_services_client:, cocina_repository:) }

    let(:cocina_with_metadata) { instance_double(Cocina::Models::DROWithMetadata, externalIdentifier: 'druid:xx999xx9999') }
    let(:workflow_client) { instance_double(Dor::Workflow::Client) }
    let(:dor_services_client) { instance_double(Dor::Services::Client) }
    let(:cocina_repository) { instance_double(DorIndexing::CocinaRepository) }
    let(:indexer) { instance_double(DorIndexing::Indexers::CompositeIndexer::Instance, to_solr: {}) }

    before do
      allow(Honeybadger).to receive(:context)
      allow(DorIndexing::Builders::DocumentBuilder).to receive(:for).and_return(indexer)
    end

    it 'builds the document' do
      expect(doc).to eq({})
      expect(DorIndexing::Builders::DocumentBuilder).to have_received(:for).with(model: cocina_with_metadata,
                                                                                 workflow_client:,
                                                                                 dor_services_client:,
                                                                                 cocina_repository:)
      expect(Honeybadger).to have_received(:context).with({ identifier: 'druid:xx999xx9999' })
    end
  end
end
