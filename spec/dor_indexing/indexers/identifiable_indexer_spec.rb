# frozen_string_literal: true

RSpec.describe DorIndexing::Indexers::IdentifiableIndexer do
  let(:druid) { 'druid:rt923jk3422' }
  let(:apo_id) { 'druid:bd999bd9999' }
  let(:cocina_item) do
    build(:dro, id: druid, admin_policy_id: apo_id).new(
      identification:
    )
  end
  let(:identification) do
    {
      catalogLinks: [
        { catalog: 'symphony', catalogRecordId: '1234', refresh: true },
        { catalog: 'previous symphony', catalogRecordId: '12345', refresh: false },
        { catalog: 'folio', catalogRecordId: 'a1234', refresh: true },
        { catalog: 'previous folio', catalogRecordId: 'a12345', refresh: false },
        { catalog: 'previous folio', catalogRecordId: 'a123456', refresh: false }
      ],
      sourceId: 'sul:1234'
    }
  end

  let(:cocina_repository) { instance_double(DorIndexing::CocinaRepository, administrative_tags: []) }

  let(:indexer) do
    described_class.new(cocina: cocina_item, cocina_repository:)
  end

  before do
    described_class.reset_cache!
  end

  describe '#identity_metadata_sources' do
    it 'indexes metadata sources' do
      expect(indexer.send(:identity_metadata_sources)).to eq %w[Folio]
    end
  end

  describe '#to_solr' do
    let(:doc) { indexer.to_solr }
    let(:mock_rel_druid) { 'druid:qf999gg9999' }
    let(:related) { build(:admin_policy, id: apo_id) }
    let(:cocina_repository) { instance_double(DorIndexing::CocinaRepository, find: related, administrative_tags: []) }

    context 'when APO is not found' do
      before do
        allow(cocina_repository).to receive(:find).and_raise(DorIndexing::CocinaRepository::RepositoryError)
      end

      it 'generates apo title fields' do
        expect(doc['apo_title_ssim'].first).to eq apo_id
        expect(doc['nonhydrus_apo_title_ssim'].first).to eq apo_id
      end
    end

    context 'when APO is found' do
      let(:related) { build(:collection, id: mock_rel_druid, admin_policy_id: apo_id, title: 'collection title') }

      it 'generates apo title fields' do
        expect(doc['apo_title_ssim'].first).to eq 'collection title'
        expect(doc['nonhydrus_apo_title_ssim'].first).to eq 'collection title'
      end

      it 'indexes metadata sources' do
        expect(doc).to match a_hash_including('metadata_source_ssim' => %w[Folio])
      end
    end

    context 'without catalogLinks' do
      let(:identification) { { sourceId: 'sul:1234' } }

      it 'indexes metadata sources' do
        expect(doc).to match a_hash_including('metadata_source_ssim' => ['DOR'])
      end
    end

    context 'with only previous-type catalogLinks' do
      let(:identification) do
        {
          catalogLinks: [
            { catalog: 'previous symphony', catalogRecordId: '12345', refresh: false },
            { catalog: 'previous folio', catalogRecordId: 'a12345', refresh: false },
            { catalog: 'previous folio', catalogRecordId: 'a123456', refresh: false }
          ],
          sourceId: 'sul:1234'
        }
      end

      it 'indexes metadata sources' do
        expect(doc).to match a_hash_including('metadata_source_ssim' => ['DOR'])
      end
    end

    context 'with no identification sub-schema' do
      let(:cocina_item) { build(:dro, id: druid, admin_policy_id: apo_id) }

      it 'indexes metadata sources' do
        expect(doc).to match a_hash_including('metadata_source_ssim' => ['DOR'])
      end
    end
  end
end
