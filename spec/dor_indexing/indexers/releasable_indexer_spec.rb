# frozen_string_literal: true

RSpec.describe DorIndexing::Indexers::ReleasableIndexer do
  let(:cocina) { build(:dro).new(administrative:) }
  let(:administrative) do
    {
      hasAdminPolicy: apo_id,
      releaseTags: release_tags
    }
  end
  let(:apo_id) { 'druid:gf999hb9999' }
  let(:release_tags) { [] }

  describe 'to_solr' do
    let(:doc) { described_class.new(cocina:, parent_collections:).to_solr }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina, release_tags: release_tags_client) }
    let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, list: release_tags) }

    before do
      allow(Dor::Services::Client).to receive(:object).with(cocina.externalIdentifier).and_return(object_client)
    end

    context 'with no parent collection' do
      let(:parent_collections) { [] }

      context 'when multiple releaseTags are present for the same destination' do
        let(:release_tags) do
          [
            Cocina::Models::ReleaseTag.new(to: 'Project', release: true, date: '2016-11-16T22:52:35.000+00:00', what: 'self'),
            Cocina::Models::ReleaseTag.new(to: 'Project', release: false, date: '2016-12-21T17:31:18.000+00:00', what: 'self'),
            Cocina::Models::ReleaseTag.new(to: 'Project', release: true, date: '2021-05-12T21:05:21.000+00:00', what: 'self'),
            Cocina::Models::ReleaseTag.new(to: 'test_target', release: true, what: 'self'),
            Cocina::Models::ReleaseTag.new(to: 'test_nontarget', release: false, date: '2016-12-16T22:52:35.000+00:00', what: 'self'),
            Cocina::Models::ReleaseTag.new(to: 'test_nontarget', release: true, date: '2016-11-16T22:52:35.000+00:00', what: 'self')
          ]
        end

        it 'indexes release tags' do
          expect(doc).to eq('released_to_ssim' => %w[Project test_target])
          # rubocop:enable Style/StringHashKeys
        end
      end

      context 'when Searchworks and Earthworks tags are present' do
        let(:release_tags) do
          [
            Cocina::Models::ReleaseTag.new(to: 'Searchworks', release: true, date: '2021-05-12T21:05:21.000+00:00', what: 'self'),
            Cocina::Models::ReleaseTag.new(to: 'Earthworks', release: true, date: '2016-11-16T22:52:35.000+00:00', what: 'self')
          ]
        end

        it 'indexes release tags' do
          # rubocop:disable Style/StringHashKeys
          expect(doc).to eq(
            'released_to_ssim' => %w[Searchworks Earthworks],
            'released_to_earthworks_dttsi' => '2016-11-16T22:52:35Z',
            'released_to_searchworks_dttsi' => '2021-05-12T21:05:21Z'
          )
          # rubocop:enable Style/StringHashKeys
        end
      end

      context 'when releaseTags are not present' do
        let(:release_tags) { [] }

        it 'has no release tags' do
          expect(doc).to be_empty
        end
      end
    end

    context 'with a parent collection' do
      let(:parent_collections) { [collection] }
      let(:collection) do
        instance_double(Cocina::Models::Collection, externalIdentifier: collection_druid, administrative: collection_administrative)
      end
      let(:collection_administrative) do
        instance_double(Cocina::Models::Administrative, releaseTags: collection_release_tags)
      end
      let(:collection_object_client) do
        instance_double(Dor::Services::Client::Object, find: collection, release_tags: collection_release_tags_client)
      end
      let(:collection_release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, list: collection_release_tags) }
      let(:collection_druid) { 'druid:bc123fg4567' }
      let(:collection_release_tags) { [] }

      before do
        allow(Dor::Services::Client).to receive(:object).with(collection_druid).and_return(collection_object_client)
      end

      context 'when the parent collection has releaseTags' do
        let(:release_tags) { [] }
        let(:collection_release_tags) do
          [
            Cocina::Models::ReleaseTag.new(to: 'test_target', release: true, date: '2016-12-21T17:31:18.000+00:00', what: 'self')
          ]
        end

        it 'indexes release tags' do
          # rubocop:disable Style/StringHashKeys
          expect(doc).to eq('released_to_ssim' => %w[test_target])
          # rubocop:enable Style/StringHashKeys
        end
      end

      context 'when the parent collection has releaseTags and the item has the same' do
        let(:release_tags) do
          [Cocina::Models::ReleaseTag.new(to: 'test_target', release: true, date: '2016-12-21T17:31:18.000+00:00', what: 'self')]
        end
        let(:collection_release_tags) do
          [Cocina::Models::ReleaseTag.new(to: 'test_target', release: true, date: '2016-12-21T17:31:18.000+00:00', what: 'self')]
        end

        it 'indexes release tags' do
          # rubocop:disable Style/StringHashKeys
          expect(doc).to eq('released_to_ssim' => %w[test_target])
          # rubocop:enable Style/StringHashKeys
        end
      end

      context 'when the parent collection has release true and item has release false' do
        let(:release_tags) do
          [
            Cocina::Models::ReleaseTag.new(to: 'test_target', release: false, date: '2016-12-21T17:31:18.000+00:00', what: 'self')
          ]
        end
        let(:collection_release_tags) do
          [
            Cocina::Models::ReleaseTag.new(to: 'test_target', release: true, date: '2016-12-21T17:31:18.000+00:00', what: 'self')
          ]
        end

        it 'indexes release tags' do
          expect(doc).to be_empty
        end
      end

      context 'when releaseTags are not present' do
        let(:release_tags) { [] }
        let(:collection_release_tags) { [] }

        it 'has no release tags' do
          expect(doc).not_to include('released_to_ssim')
        end
      end
    end
  end
end
