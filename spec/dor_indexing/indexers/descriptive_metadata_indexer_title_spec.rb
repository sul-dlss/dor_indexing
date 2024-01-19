# frozen_string_literal: true

RSpec.describe DorIndexing::Indexers::DescriptiveMetadataIndexer do
  subject(:indexer) { described_class.new(cocina:) }

  let(:bare_druid) { 'qy781dy0220' }
  let(:druid) { "druid:#{bare_druid}" }
  let(:doc) { indexer.to_solr }
  let(:cocina) do
    build(:dro, id: druid).new(
      description: description.merge(purl: "https://purl.stanford.edu/#{bare_druid}")
    )
  end

  describe 'title mappings from Cocina to Solr sw_display_title_tesim' do
    describe 'single untyped title' do
      # Select value; status: primary may or may not be present
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ]
        }
      end

      it 'uses title value' do
        expect(doc['sw_display_title_tesim']).to eq 'Title'
      end
    end

    describe 'single typed title' do
      # Select value; status: primary may or may not be present
      let(:description) do
        {
          title: [
            {
              value: 'Title',
              type: 'translated'
            }
          ]
        }
      end

      it 'uses title value' do
        expect(doc['sw_display_title_tesim']).to eq 'Title'
      end
    end

    describe 'multiple untyped titles, one primary' do
      # Select primary
      let(:description) do
        {
          title: [
            {
              value: 'Title 1'
            },
            {
              value: 'Title 2',
              status: 'primary'
            }
          ]
        }
      end

      it 'uses value from title with status primary' do
        expect(doc['sw_display_title_tesim']).to eq 'Title 2'
      end
    end

    describe 'multiple untyped titles, none primary' do
      # Select first
      let(:description) do
        {
          title: [
            {
              value: 'Title 1'
            },
            {
              value: 'Title 2'
            }
          ]
        }
      end

      it 'uses first value' do
        expect(doc['sw_display_title_tesim']).to eq 'Title 1'
      end
    end

    describe 'multiple typed and untyped titles, one primary' do
      let(:description) do
        {
          title: [
            {
              value: 'Title 1',
              type: 'translated',
              status: 'primary'
            },
            {
              value: 'Title 2'
            }
          ]
        }
      end

      it 'uses value from title with status primary' do
        expect(doc['sw_display_title_tesim']).to eq 'Title 1'
      end
    end

    describe 'multiple typed and untyped titles, none primary' do
      # Select first without type
      let(:description) do
        {
          title: [
            {
              value: 'Title 1',
              type: 'alternative'
            },
            {
              value: 'Title 2'
            },
            {
              value: 'Title 3'
            }
          ]
        }
      end

      it 'uses value from first title without type' do
        expect(doc['sw_display_title_tesim']).to eq 'Title 2'
      end
    end

    describe 'multiple typed titles, one primary' do
      # Select primary
      let(:description) do
        {
          title: [
            {
              value: 'Title 2',
              type: 'alternative'
            },
            {
              value: 'Title 1',
              type: 'translated',
              status: 'primary'
            }
          ]
        }
      end

      it 'uses value from title with status primary' do
        expect(doc['sw_display_title_tesim']).to eq 'Title 1'
      end
    end

    describe 'multiple typed titles, none primary' do
      # Select first
      let(:description) do
        {
          title: [
            {
              value: 'Title 1',
              type: 'translated'
            },
            {
              value: 'Title 2',
              type: 'alternative'
            }
          ]
        }
      end

      it 'uses value from first title' do
        expect(doc['sw_display_title_tesim']).to eq 'Title 1'
      end
    end

    describe 'nonsorting character count' do
      # Note doesn't matter for display value
      let(:description) do
        {
          title: [
            {
              value: 'A title',
              note: [
                {
                  type: 'nonsorting character count',
                  value: '2'
                }
              ]
            }
          ]
        }
      end

      it 'uses full value from title' do
        expect(doc['sw_display_title_tesim']).to eq 'A title'
      end
    end

    describe 'parallelValue with primary on value' do
      # Select primary
      let(:description) do
        {
          title: [
            {
              parallelValue: [
                {
                  value: 'Title 1'
                },
                {
                  value: 'Title 2',
                  status: 'primary'
                }
              ]
            }
          ]
        }
      end

      it 'uses value with status primary' do
        expect(doc['sw_display_title_tesim']).to eq 'Title 2'
      end
    end

    describe 'parallelValue with primary on parallelValue' do
      # Select first value in primary parallelValue
      let(:description) do
        {
          title: [
            {
              parallelValue: [
                {
                  value: 'Title 1'
                },
                {
                  value: 'Title 2'
                }
              ],
              status: 'primary'
            }
          ]
        }
      end

      it 'uses first value from parallelValue with status primary' do
        expect(doc['sw_display_title_tesim']).to eq 'Title 1'
      end
    end

    describe 'parallelValue with primary on value and parallelValue' do
      # Select primary value in primary parallelValue
      let(:description) do
        {
          title: [
            {
              parallelValue: [
                {
                  value: 'Title 1'
                },
                {
                  value: 'Title 2',
                  status: 'primary'
                }
              ],
              status: 'primary'
            }
          ]
        }
      end

      it 'uses value with status primary in parallelValue' do
        expect(doc['sw_display_title_tesim']).to eq 'Title 2'
      end
    end

    describe 'primary on both parallelValue value and other value' do
      # Select other value with primary; parallelValue primary value is primary within
      # parallelValue but the parallelValue is not itself the primary title
      let(:description) do
        {
          title: [
            {
              parallelValue: [
                {
                  value: 'Title 1',
                  status: 'primary'
                },
                {
                  value: 'Title 2'
                }
              ]
            },
            {
              value: 'Title 3',
              status: 'primary'
            }
          ]
        }
      end

      it 'uses value from outermost title with status primary' do
        expect(doc['sw_display_title_tesim']).to eq 'Title 3'
      end
    end

    describe 'parallelValue with additional value, parallelValue first, no primary' do
      # Select first value, in this case inside parallelValue
      let(:description) do
        {
          title: [
            {
              parallelValue: [
                {
                  value: 'Title 1'
                },
                {
                  value: 'Title 2'
                }
              ]
            },
            {
              value: 'Title 3'
            }
          ]
        }
      end

      it 'uses first value' do
        expect(doc['sw_display_title_tesim']).to eq 'Title 1'
      end
    end

    describe 'parallelValue with additional value, value first, no primary' do
      # Select first value
      let(:description) do
        {
          title: [
            {
              value: 'Title 3'
            },
            {
              parallelValue: [
                {
                  value: 'Title 1'
                },
                {
                  value: 'Title 2'
                }
              ]
            }
          ]
        }
      end

      it 'uses first value' do
        expect(doc['sw_display_title_tesim']).to eq 'Title 3'
      end
    end

    # **** Constructing title from structuredValue ****

    # nonsorting characters value is followed by a space, unless the nonsorting
    #   character count note has a numeric value equal to the length of the
    #   nonsorting characters value, in which case no space is inserted
    # subtitle is preceded by space colon space, unless it is at the beginning
    #   of the title string
    # partName and partNumber are always separated from each other by comma space
    # first partName or partNumber in the string is preceded by period space
    # partName or partNumber before nonsorting characters or main title is followed
    #   by period space
    describe 'structuredValue with all parts in common order' do
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                {
                  value: 'A',
                  type: 'nonsorting characters'
                },
                {
                  value: 'title',
                  type: 'main title'
                },
                {
                  value: 'a subtitle',
                  type: 'subtitle'
                },
                {
                  value: 'Vol. 1',
                  type: 'part number'
                },
                {
                  value: 'Supplement',
                  type: 'part name'
                }
              ]
            }
          ]
        }
      end

      it 'constructs title from structuredValue' do
        expect(doc['sw_display_title_tesim']).to eq 'A title : a subtitle. Vol. 1, Supplement'
      end
    end

    describe 'structuredValue with parts in uncommon order' do
      # improvement on stanford_mods in that it respects field order as given
      # based on ckey 9803970
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                {
                  value: 'The',
                  type: 'nonsorting characters'
                },
                {
                  value: 'title',
                  type: 'main title'
                },
                {
                  value: 'Vol. 1',
                  type: 'part number'
                },
                {
                  value: 'Supplement',
                  type: 'part name'
                },
                {
                  value: 'a subtitle',
                  type: 'subtitle'
                }
              ]
            }
          ]
        }
      end

      it 'constructs title from structuredValue, respecting order of occurrence' do
        skip 'Naomi is fixing the title reconstruction order'
        expect(doc['sw_display_title_tesim']).to eq 'The title. Vol. 1, Supplement : a subtitle'
      end
    end

    describe 'structuredValue with multiple partName and partNumber' do
      # improvement on stanford_mods in that it respects field order as given
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                {
                  value: 'Title',
                  type: 'main title'
                },
                {
                  value: 'Special series',
                  type: 'part name'
                },
                {
                  value: 'Vol. 1',
                  type: 'part number'
                },
                {
                  value: 'Supplement',
                  type: 'part name'
                }
              ]
            }
          ]
        }
      end

      it 'constructs title from structuredValue, respecting order of occurrence' do
        expect(doc['sw_display_title_tesim']).to eq 'Title. Special series, Vol. 1, Supplement'
      end
    end

    describe 'structuredValue with part before title' do
      # improvement on stanford_mods in that it respects field order as given
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                {
                  value: 'Series 1',
                  type: 'part number'
                },
                {
                  value: 'Title',
                  type: 'main title'
                }
              ]
            }
          ]
        }
      end

      it 'constructs title from structuredValue, respecting order of occurrence' do
        skip 'Naomi is fixing the title reconstruction order'
        expect(doc['sw_display_title_tesim']).to eq 'Series 1. Title'
      end
    end

    describe 'structuredValue with nonsorting character count' do
      # improvement on stanford_mods in that it does not force a space separator
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                {
                  value: "L'",
                  type: 'nonsorting characters'
                },
                {
                  value: 'autre title',
                  type: 'main title'
                }
              ],
              note: [
                {
                  value: '2',
                  type: 'nonsorting character count'
                }
              ]
            }
          ]
        }
      end

      it 'constructs title from structuredValue, respecting order of occurrence' do
        expect(doc['sw_display_title_tesim']).to eq 'L\'autre title'
      end
    end

    describe 'structuredValue for uniform title' do
      # Omit author name when uniform title is preferred title for display
      let(:description) do
        {
          title: [
            {
              value: 'Title',
              type: 'uniform',
              note: [
                {
                  value: 'Author, An',
                  type: 'associated name'
                }
              ]
            }
          ],
          contributor: [
            {
              name: [
                {
                  value: 'Author, An'
                }
              ]
            }
          ]
        }
      end

      it 'constructs title from structuredValue without author name' do
        expect(doc['sw_display_title_tesim']).to eq 'Title'
      end
    end

    # Handling punctuation

    describe 'punctuation/space in simple value' do
      # strip one or more instances of .,;:/\ plus whitespace at beginning or end of string
      let(:description) do
        {
          title: [
            {
              value: 'Title /'
            }
          ]
        }
      end

      it 'uses value with trailing punctuation of .,;:/\ stripped' do
        expect(doc['sw_display_title_tesim']).to eq 'Title'
      end
    end

    describe 'punctuation/space in structuredValue' do
      # strip one or more instances of .,;:/\ plus whitespace at beginning or end of string
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                {
                  value: 'Title.',
                  type: 'main title'
                },
                {
                  value: ':subtitle',
                  type: 'subtitle'
                }
              ]
            }
          ]
        }
      end

      it 'uses value with trailing whitespace or punctuation [.,;:/\] stripped' do
        expect(doc['sw_display_title_tesim']).to eq 'Title : subtitle'
      end
    end

    # Added by devs

    describe 'only has subtitle' do
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                {
                  value: 'subtitle',
                  type: 'subtitle'
                }
              ]
            }
          ]
        }
      end

      it 'uses correct punctuation' do
        expect(doc['sw_display_title_tesim']).to eq 'subtitle'
      end
    end

    describe 'starts with subtitle, has part name and part number' do
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                {
                  value: 'subtitle',
                  type: 'subtitle'
                },
                {
                  value: 'part name',
                  type: 'part name'
                },
                {
                  value: 'part number',
                  type: 'part number'
                }
              ]
            }
          ]
        }
      end

      # partName and partNumber are always separated from each other by comma space
      # first partName or partNumber in the string is preceded by period space
      it 'uses correct punctuation' do
        expect(doc['sw_display_title_tesim']).to eq 'subtitle. part name, part number'
      end
    end

    describe 'starts with subtitle, has part number and part name' do
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                {
                  value: 'subtitle',
                  type: 'subtitle'
                },
                {
                  value: 'part number',
                  type: 'part number'
                },
                {
                  value: 'part name',
                  type: 'part name'
                }
              ]
            }
          ]
        }
      end

      # partName and partNumber are always separated from each other by comma space
      # first partName or partNumber in the string is preceded by period space
      it 'uses correct punctuation' do
        expect(doc['sw_display_title_tesim']).to eq 'subtitle. part number, part name'
      end
    end

    describe 'nonsorting characters not first' do
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                {
                  value: 'Series 1',
                  type: 'part number'
                },
                {
                  value: 'A',
                  type: 'nonsorting characters'
                },
                {
                  value: 'Title',
                  type: 'main title'
                }
              ]
            }
          ]
        }
      end

      it 'uses correct punctuation and respects order of occurrence' do
        skip 'Naomi is fixing the title reconstruction order'
        expect(doc['sw_display_title_tesim']).to eq 'Series 1. A Title'
      end
    end
  end
end
