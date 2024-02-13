# frozen_string_literal: true

RSpec.describe DorIndexing::Indexers::CompositeIndexer do
  let(:druid) { 'druid:mx123ms3333' }
  let(:apo_id) { 'druid:gf999hb9999' }
  let(:apo) { build(:admin_policy, id: apo_id, title: 'test admin policy') }
  let(:indexer) do
    described_class.new(
      DorIndexing::Indexers::DescriptiveMetadataIndexer,
      DorIndexing::Indexers::IdentifiableIndexer
    )
  end

  let(:cocina_item) do
    build(:dro, id: druid).new(
      description: {
        title: [{ value: 'Test item' }],
        subject: [{ type: 'topic', value: 'word' }],
        purl: 'https://purl.stanford.edu/mx123ms3333'
      }
    )
  end
  let(:cocina_repository) { instance_double(DorIndexing::CocinaRepository, find: apo, administrative_tags: []) }

  describe 'to_solr' do
    let(:status) do
      instance_double(Dor::Workflow::Client::Status, milestones: {}, display: 'bad')
    end
    let(:workflow_client) { instance_double(Dor::Workflow::Client, status:) }
    let(:doc) { indexer.new(id: druid, cocina: cocina_item, workflow_client:, cocina_repository:).to_solr }

    it 'calls each of the provided indexers and combines the results' do
      expect(doc).to eq(
        'descriptive_tiv' => 'Test item word',
        'descriptive_teiv' => 'Test item word',
        'descriptive_text_nostem_i' => 'Test item word',
        'main_title_tenim' => ['Test item'],
        'full_title_tenim' => ['Test item'],
        'display_title_ss' => 'Test item',
        'sw_display_title_tesim' => 'Test item',
        'nonhydrus_apo_title_ssim' => ['test admin policy'],
        'apo_title_ssim' => ['test admin policy'],
        'metadata_source_ssim' => ['DOR'],
        'druid_bare_ssi' => 'mx123ms3333',
        'druid_prefixed_ssi' => 'druid:mx123ms3333',
        'objectId_tesim' => ['druid:mx123ms3333', 'mx123ms3333'],
        'topic_ssim' => ['word'],
        'topic_tesim' => ['word']
      )
      # rubocop:enable Style/StringHashKeys
    end
  end
end
