# frozen_string_literal: true

RSpec.describe DorIndexing::Builders::DocumentBuilder do
  subject(:indexer) do
    described_class.for(model: cocina_with_metadata, workflow_client:, cocina_finder:, administrative_tags_finder:, release_tags_finder:)
  end

  let(:cocina_with_metadata) do
    Cocina::Models.with_metadata(cocina, 'unknown_lock', created: DateTime.parse('Wed, 01 Jan 2020 12:00:01 GMT'),
                                                         modified: DateTime.parse('Thu, 04 Mar 2021 23:05:34 GMT'))
  end

  let(:cocina_finder) { ->(_druid) {} }
  let(:administrative_tags_finder) { ->(_druid) { [] } }
  let(:release_tags_finder) { ->(_druid) {} }
  let(:workflow_client) { instance_double(Dor::Workflow::Client) }
  let(:druid) { 'druid:xx999xx9999' }
  let(:releasable) do
    instance_double(DorIndexing::Indexers::ReleasableIndexer, to_solr: { 'released_to_ssim' => %w[searchworks earthworks] })
  end
  let(:workflows) do
    instance_double(DorIndexing::Indexers::WorkflowsIndexer, to_solr: { 'wf_ssim' => ['accessionWF'] })
  end
  let(:admin_tags) do
    instance_double(DorIndexing::Indexers::AdministrativeTagIndexer, to_solr: { 'tag_ssim' => ['Test : Tag'] })
  end
  # rubocop:enable Style/StringHashKeys

  before do
    described_class.reset_parent_collections
    allow(DorIndexing::WorkflowFields).to receive(:for).and_return({ milestones_ssim: %w[foo bar] })
    allow(DorIndexing::Indexers::ReleasableIndexer).to receive(:new).and_return(releasable)
    allow(DorIndexing::Indexers::WorkflowsIndexer).to receive(:new).and_return(workflows)
    allow(DorIndexing::Indexers::AdministrativeTagIndexer).to receive(:new).and_return(admin_tags)
  end

  context 'when the model is an item' do
    let(:cocina) do
      build(:dro, id: druid).new(
        structural: {
          isMemberOf: collections
        }
      )
    end

    context 'without collections' do
      let(:collections) { [] }

      it { is_expected.to be_instance_of DorIndexing::Indexers::CompositeIndexer::Instance }
    end

    context 'with collections' do
      let(:cocina_finder) { ->(_druid) { related } }
      let(:related) { build(:collection) }
      let(:collections) { ['druid:bc999df2323'] }

      before { allow(cocina_finder).to receive(:call).and_call_original }

      it 'returns indexer' do
        expect(indexer).to be_instance_of DorIndexing::Indexers::CompositeIndexer::Instance
        expect(cocina_finder).to have_received(:call).once
      end
    end

    context 'with a cached collections' do
      let(:cocina_finder) { ->(_druid) { related } }
      let(:related) { build(:collection) }
      let(:collections) { ['druid:bc999df2323'] }

      before do
        allow(cocina_finder).to receive(:call).and_call_original
        described_class.for(
          model: cocina_with_metadata,
          cocina_finder:,
          workflow_client:,
          administrative_tags_finder:,
          release_tags_finder:
        )
      end

      it 'uses the cached collection' do
        expect(indexer).to be_instance_of DorIndexing::Indexers::CompositeIndexer::Instance
        expect(cocina_finder).to have_received(:call).once
      end
    end

    context "with collections that can't be resolved" do
      let(:collections) { ['druid:bc999df2323'] }
      let(:cocina_finder) { ->(_druid) { raise DorIndexing::RepositoryError } }

      it 'logs to honeybadger' do
        allow(Honeybadger).to receive(:notify).and_return('16ae4ff7-9449-43af-9988-77772858878c')
        expect(indexer).to be_instance_of DorIndexing::Indexers::CompositeIndexer::Instance

        # Ensure that errors are stripped out of parent_collections
        expect(DorIndexing::Indexers::AdministrativeTagIndexer).to have_received(:new)
          .with(cocina: Cocina::Models::DROWithMetadata,
                id: String,
                administrative_tags: [],
                parent_collections: [],
                workflow_client:,
                cocina_finder:,
                administrative_tags_finder:,
                release_tags_finder:)
        expect(Honeybadger).to have_received(:notify).with('Bad association found on druid:xx999xx9999. druid:bc999df2323 could not be found')
      end
    end
  end

  context 'when the model is an admin policy' do
    let(:cocina) { build(:admin_policy) }

    it { is_expected.to be_instance_of DorIndexing::Indexers::CompositeIndexer::Instance }
  end

  context 'when the model is a collection' do
    let(:cocina) { build(:collection) }

    it { is_expected.to be_instance_of DorIndexing::Indexers::CompositeIndexer::Instance }
  end

  context 'when the model is an agreement' do
    let(:cocina) { build(:dro, type: Cocina::Models::ObjectType.agreement) }

    it { is_expected.to be_instance_of DorIndexing::Indexers::CompositeIndexer::Instance }
  end

  describe '#to_solr' do
    subject(:solr_doc) { indexer.to_solr }

    let(:apo_id) { 'druid:bd999bd9999' }
    let(:apo) { build(:admin_policy, id: apo_id) }
    let(:cocina_finder) { ->(_druid) { apo } }

    context 'when the model is an item' do
      let(:cocina) do
        build(:dro, id: druid, admin_policy_id: apo_id).new(
          description: {
            title: [{ value: 'Test obj' }],
            purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}",
            subject: [{ type: 'topic', value: 'word' }],
            event: [
              {
                type: 'creation',
                date: [
                  {
                    value: '2021-01-01',
                    status: 'primary',
                    encoding: {
                      code: 'w3cdtf'
                    },
                    type: 'creation'
                  }
                ]
              },
              {
                type: 'publication',
                location: [
                  {
                    value: 'Moskva'
                  }
                ],
                contributor: [
                  {
                    name: [
                      {
                        value: 'Izdatelʹstvo "Vesʹ Mir"'
                      }
                    ],
                    type: 'organization',
                    role: [{ value: 'publisher' }]
                  }
                ]
              }
            ]
          }
        )
      end

      it 'has required fields' do
        expect(solr_doc).to include('milestones_ssim', 'wf_ssim', 'tag_ssim')

        expect(solr_doc['originInfo_date_created_tesim']).to eq '2021-01-01'
        expect(solr_doc['originInfo_publisher_tesim']).to eq 'Izdatelʹstvo "Vesʹ Mir"'
        expect(solr_doc['originInfo_place_placeTerm_tesim']).to eq 'Moskva'
      end
    end

    context 'when the model is an admin policy' do
      let(:model) { Dor::AdminPolicyObject.new(pid: druid) }
      let(:cocina) do
        build(:admin_policy, id: druid).new(
          administrative: {
            hasAdminPolicy: apo_id,
            hasAgreement: 'druid:bb033gt0615',
            accessTemplate: { view: 'world', download: 'world' }
          }
        )
      end

      it { is_expected.to include('milestones_ssim', 'wf_ssim', 'tag_ssim') }
    end

    context 'when the model is a hydrus apo' do
      let(:model) { Hydrus::AdminPolicyObject.new(pid: druid) }
      let(:cocina) do
        build(:admin_policy, id: druid).new(
          administrative: {
            hasAdminPolicy: apo_id,
            hasAgreement: 'druid:bb033gt0615',
            accessTemplate: { view: 'world', download: 'world' }
          }
        )
      end

      it { is_expected.to include('milestones_ssim', 'wf_ssim', 'tag_ssim') }
    end
  end
end
