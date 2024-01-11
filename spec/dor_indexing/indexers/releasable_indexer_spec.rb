# frozen_string_literal: true

RSpec.describe DorIndexing::Indexers::ReleasableIndexer do
  let(:apo_id) { 'druid:gf999hb9999' }
  let(:cocina) { build(:dro).new(administrative:) }

  describe 'to_solr' do
    let(:doc) { described_class.new(cocina:, parent_collections:).to_solr }

    context 'with no parent collection' do
      let(:parent_collections) { [] }

      context 'when multiple releaseTags are present for the same destination' do
        let(:administrative) do
          {
            hasAdminPolicy: apo_id,
            releaseTags: [
              { to: 'Project', release: true, date: '2016-11-16T22:52:35.000+00:00' },
              { to: 'Project', release: false, date: '2016-12-21T17:31:18.000+00:00' },
              { to: 'Project', release: true, date: '2021-05-12T21:05:21.000+00:00' },
              { to: 'test_target', release: true },
              { to: 'test_nontarget', release: false, date: '2016-12-16T22:52:35.000+00:00' },
              { to: 'test_nontarget', release: true, date: '2016-11-16T22:52:35.000+00:00' }
            ]
          }
        end

        it 'indexes release tags' do
          expect(doc).to eq('released_to_ssim' => %w[Project test_target])
          # rubocop:enable Style/StringHashKeys
        end
      end

      context 'when Searchworks and Earthworks tags are present' do
        let(:administrative) do
          {
            hasAdminPolicy: apo_id,
            releaseTags: [
              { to: 'Searchworks', release: true, date: '2021-05-12T21:05:21.000+00:00' },
              { to: 'Earthworks', release: true, date: '2016-11-16T22:52:35.000+00:00' }
            ]
          }
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
        let(:administrative) do
          {
            hasAdminPolicy: apo_id
          }
        end

        it 'has no release tags' do
          expect(doc).to be_empty
        end
      end
    end

    context 'with a parent collection' do
      let(:parent_collections) do
        [instance_double(Cocina::Models::Collection, administrative: collection_administrative)]
      end
      let(:collection_administrative) do
        instance_double(Cocina::Models::Administrative, releaseTags: collection_release_tags)
      end

      let(:administrative) do
        {
          hasAdminPolicy: apo_id
        }
      end

      context 'when the parent collection has releaseTags' do
        let(:collection_release_tags) do
          [
            Cocina::Models::ReleaseTag.new(to: 'Project', release: true, date: '2016-11-16T22:52:35.000+00:00', what: 'self'),
            Cocina::Models::ReleaseTag.new(to: 'test_target', release: true, date: '2016-12-21T17:31:18.000+00:00', what: 'collection')
          ]
        end

        it 'indexes release tags' do
          # rubocop:disable Style/StringHashKeys
          expect(doc).to eq('released_to_ssim' => %w[test_target])
          # rubocop:enable Style/StringHashKeys
        end
      end

      context 'when the parent collection has releaseTags and the item has the same' do
        let(:collection_release_tags) do
          [
            Cocina::Models::ReleaseTag.new(to: 'Project', release: true, date: '2016-11-16T22:52:35.000+00:00', what: 'self'),
            Cocina::Models::ReleaseTag.new(to: 'test_target', release: true, date: '2016-12-21T17:31:18.000+00:00', what: 'collection')
          ]
        end
        let(:administrative) do
          {
            hasAdminPolicy: apo_id,
            releaseTags: [
              { to: 'test_target', release: true }
            ]
          }
        end

        it 'indexes release tags' do
          # rubocop:disable Style/StringHashKeys
          expect(doc).to eq('released_to_ssim' => %w[test_target])
          # rubocop:enable Style/StringHashKeys
        end
      end

      context 'when the parent collection has release true and item has release false' do
        let(:collection_release_tags) do
          [
            Cocina::Models::ReleaseTag.new(to: 'Project', release: true, date: '2016-11-16T22:52:35.000+00:00', what: 'self'),
            Cocina::Models::ReleaseTag.new(to: 'test_target', release: true, date: '2016-12-21T17:31:18.000+00:00', what: 'collection')
          ]
        end
        let(:administrative) do
          {
            hasAdminPolicy: apo_id,
            releaseTags: [
              { to: 'test_target', release: false }
            ]
          }
        end

        it 'indexes release tags' do
          expect(doc).to be_empty
        end
      end

      context 'when releaseTags are not present' do
        let(:collection_release_tags) { [] }

        it 'has no release tags' do
          expect(doc).not_to include('released_to_ssim')
        end
      end
    end
  end
end
