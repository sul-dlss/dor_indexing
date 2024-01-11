# frozen_string_literal: true

RSpec.describe DorIndexing::Indexers::CollectionTitleIndexer do
  let(:druid) { 'druid:rt923jk3422' }
  let(:apo_id) { 'druid:bd999bd9999' }
  let(:cocina_item) { build(:dro, id: druid) }
  let(:indexer) { described_class.new(cocina: cocina_item, parent_collections: collections, administrative_tags: []) }

  describe '#to_solr' do
    let(:doc) { indexer.to_solr }
    let(:bare_collection_druid) { 'qf999gg9999' }
    let(:collection_druid) { "druid:#{bare_collection_druid}" }

    context 'when no collections are provided' do
      let(:collections) { [] }

      it "doesn't raise an error" do
        expect(doc[Solrizer.solr_name('collection_title', :symbol)]).to be_nil
        expect(doc[Solrizer.solr_name('collection_title', :stored_searchable)]).to be_nil
      end
    end

    context 'when related collections are provided' do
      let(:collections) { [collection] }
      let(:collection) { build(:collection, id: collection_druid, title: 'Collection test object') }

      it 'generates collection title fields' do
        expect(doc[Solrizer.solr_name('collection_title', :symbol)].first).to eq 'Collection test object'
        expect(doc[Solrizer.solr_name('collection_title', :stored_searchable)].first).to eq 'Collection test object'
      end
    end
  end
end
