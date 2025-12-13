require 'rails_helper'

RSpec.describe RecipeImporter, type: :command do
  subject(:command) { described_class.call }

  let(:json_data) do
    [
      {
        "title" => "Spaghetti Carbonara",
        "cook_time" => "20",
        "prep_time" => "10",
        "ingredients" => [ "pasta", "eggs", "bacon", "parmesan" ],
        "ratings" => "4.5",
        "cuisine" => "Italian",
        "category" => "Pasta",
        "author" => "Chef Mario",
        "image" => "https://imagesvc.meredithcorp.io/v3/mm/image?url=https%3A%2F%2Fstatic.onecms.io%2Fwp-content%2Fuploads%2Fsites%2F43%2F2021%2F10%2F26%2Fcarbonara.jpg"
      },
      {
        "title" => "Margherita Pizza",
        "cook_time" => "15",
        "prep_time" => "30",
        "ingredients" => [ "dough", "tomato sauce", "mozzarella", "basil" ],
        "ratings" => "4.8",
        "cuisine" => "Italian",
        "category" => "Pizza",
        "author" => "Chef Luigi",
        "image" => "https://imagesvc.meredithcorp.io/v3/mm/image?url=https%3A%2F%2Fimages.media-allrecipes.com%2Fuserphotos%2F50654.jpg"
      }
    ]
  end

  let(:json_content) { json_data.to_json }

  before do
    # Clean up any existing test files
    FileUtils.rm_f(described_class::JSON_FILE_PATH)
    FileUtils.rm_f(described_class::GZ_FILE_PATH)

    # Suppress puts output in tests
    allow($stdout).to receive(:puts)
    allow($stdout).to receive(:print)
  end

  after do
    FileUtils.rm_f(described_class::JSON_FILE_PATH)
    FileUtils.rm_f(described_class::GZ_FILE_PATH)
  end

  def stub_services(data = nil)
    content = data ? data.to_json : json_content

    allow(FileDownloader).to receive(:call).and_return(
      instance_double(FileDownloader, success?: true, failure?: false, result: described_class::GZ_FILE_PATH)
    )

    allow(GzipExtractor).to receive(:call).and_return(
      instance_double(GzipExtractor, success?: true, failure?: false, result: content)
    )
  end

  shared_context 'with default stubs' do
    before do
      stub_services
    end
  end

  describe '#call' do
    include_context 'with default stubs'

    it 'imports recipes successfully' do
      expect(command).to be_success
      expect(Recipe.count).to eq(2)
    end

    it 'creates categories from recipe data' do
      command

      expect(Category.count).to eq(2)
      expect(Category.pluck(:name)).to contain_exactly('Pasta', 'Pizza')
    end

    it 'creates authors from recipe data' do
      command

      expect(Author.count).to eq(2)
      expect(Author.pluck(:name)).to contain_exactly('Chef Mario', 'Chef Luigi')
    end

    it 'tracks statistics correctly' do
      result = command

      expect(result.stats[:recipes]).to eq(2)
      expect(result.stats[:categories]).to eq(2)
      expect(result.stats[:authors]).to eq(2)
      expect(result.stats[:errors]).to be_empty
    end

    it 'calls FileDownloader with correct parameters' do
      command

      expect(FileDownloader).to have_received(:call).with(
        url: described_class::RECIPES_URL,
        destination: described_class::GZ_FILE_PATH
      )
    end

    it 'calls GzipExtractor with correct parameters' do
      command

      expect(GzipExtractor).to have_received(:call).with(
        source: described_class::GZ_FILE_PATH,
        destination: described_class::JSON_FILE_PATH
      )
    end

    context 'when JSON file already exists' do
      before do
        FileUtils.mkdir_p(File.dirname(described_class::JSON_FILE_PATH))
        File.write(described_class::JSON_FILE_PATH, json_content)
      end

      it 'uses existing JSON file without downloading' do
        command

        expect(FileDownloader).not_to have_received(:call)
        expect(GzipExtractor).not_to have_received(:call)
      end

      it 'imports recipes from cached file' do
        expect(command).to be_success
        expect(Recipe.count).to eq(2)
      end
    end

    context 'when FileDownloader fails' do
      before do
        allow(FileDownloader).to receive(:call).and_return(
          instance_double(
            FileDownloader,
            success?: false,
            failure?: true,
            errors: double(message: 'Download failed: Network error')
          )
        )
      end

      it 'aborts with download_failed error' do
        result = command

        expect(result).to be_failure
        expect(result.errors.as_key).to eq(:import_download_failed)
        expect(result.errors.message).to include('Download failed')
      end

      it 'does not create any recipes' do
        command

        expect(Recipe.count).to eq(0)
      end

      it 'does not call GzipExtractor' do
        allow(GzipExtractor).to receive(:call)

        command

        expect(GzipExtractor).not_to have_received(:call)
      end
    end

    context 'when GzipExtractor fails' do
      before do
        allow(GzipExtractor).to receive(:call).and_return(
          instance_double(
            GzipExtractor,
            success?: false,
            failure?: true,
            errors: double(message: 'Extraction failed: Invalid gzip')
          )
        )
      end

      it 'calls FileDownloader' do
        allow(FileDownloader).to receive(:call).and_return(
          instance_double(FileDownloader, success?: true, failure?: false, result: described_class::GZ_FILE_PATH)
        )

        command

        expect(FileDownloader).to have_received(:call)
      end

      it 'aborts with extraction_failed error' do
        result = command

        expect(result).to be_failure
        expect(result.errors.as_key).to eq(:import_extraction_failed)
        expect(result.errors.message).to include('Extraction failed')
      end

      it 'does not create any recipes' do
        command

        expect(Recipe.count).to eq(0)
      end
    end

    context 'when JSON parsing fails' do
      before do
        allow(GzipExtractor).to receive(:call).and_return(
          instance_double(GzipExtractor, success?: true, failure?: false, result: 'invalid json')
        )
      end

      it 'aborts with parse_error' do
        result = command

        expect(result).to be_failure
        expect(result.errors.as_key).to eq(:import_parse_error)
        expect(result.errors.message).to include('Failed to parse JSON')
      end
    end

    context 'with recipe data variations' do
      context 'when recipe has no category' do
        before do
          test_data = [
            {
              "title" => "Test Recipe",
              "cook_time" => "30",
              "prep_time" => "15",
              "ingredients" => [ "flour" ],
              "category" => nil,
              "author" => "Test Author"
            }
          ]
          stub_services(test_data)
        end

        it 'handles recipes without category' do
          command

          expect(Recipe.count).to eq(1)
          expect(Recipe.first.category).to be_nil
        end
      end

      context 'when recipe has no author' do
        before do
          test_data = [
            {
              "title" => "Test Recipe",
              "cook_time" => "30",
              "prep_time" => "15",
              "ingredients" => [ "flour" ],
              "category" => "Desserts",
              "author" => nil
            }
          ]
          stub_services(test_data)
        end

        it 'handles recipes without author' do
          command

          expect(Recipe.count).to eq(1)
          expect(Recipe.first.author).to be_nil
        end
      end

      context 'when category name is blank' do
        before do
          test_data = [
            {
              "title" => "Test Recipe",
              "cook_time" => "30",
              "prep_time" => "15",
              "ingredients" => [ "flour" ],
              "category" => "",
              "author" => "Test Author"
            }
          ]
          stub_services(test_data)
        end

        it 'handles blank category names' do
          command

          expect(Recipe.count).to eq(1)
          expect(Recipe.first.category).to be_nil
        end
      end

      context 'when author name is blank' do
        before do
          test_data = [
            {
              "title" => "Test Recipe",
              "cook_time" => "30",
              "prep_time" => "15",
              "ingredients" => [ "flour" ],
              "category" => "Desserts",
              "author" => ""
            }
          ]
          stub_services(test_data)
        end

        it 'handles blank author names' do
          command

          expect(Recipe.count).to eq(1)
          expect(Recipe.first.author).to be_nil
        end
      end
    end

    context 'with duplicate categories and authors' do
        let(:duplicate_data) do
          [
            {
              "title" => "Recipe 1",
              "ingredients" => [ "flour" ],
              "category" => "Italian",
              "author" => "Chef Mario"
            },
            {
              "title" => "Recipe 2",
              "ingredients" => [ "sugar" ],
              "category" => "Italian",
              "author" => "Chef Mario"
            }
          ]
      end

      before do
        allow(FileDownloader).to receive(:call).and_return(
          instance_double(FileDownloader, success?: true, failure?: false, result: described_class::GZ_FILE_PATH)
        )
        allow(GzipExtractor).to receive(:call).and_return(
          instance_double(GzipExtractor, success?: true, failure?: false, result: duplicate_data.to_json)
        )
      end

      it 'reuses existing category' do
        result = command

        expect(Category.count).to eq(1)
        expect(result.stats[:categories]).to eq(1)
      end

      it 'reuses existing author' do
        result = command

        expect(Author.count).to eq(1)
        expect(result.stats[:authors]).to eq(1)
      end
    end

    context 'when individual recipe import fails' do
      before do
        mixed_data = [
          {
            "title" => "Valid Recipe",
            "cook_time" => "30",
            "prep_time" => "15",
            "ingredients" => [ "flour" ],
            "category" => "Desserts",
            "author" => "Chef Mario"
          },
          {
            "title" => nil, # Invalid - will fail validation
            "cook_time" => "25",
            "prep_time" => "10",
            "ingredients" => [ "sugar" ],
            "category" => "Desserts",
            "author" => "Chef Luigi"
          },
          {
            "title" => "Another Valid Recipe",
            "cook_time" => "20",
            "prep_time" => "5",
            "ingredients" => [ "eggs" ],
            "category" => "Breakfast",
            "author" => "Chef Anna"
          }
        ]
        stub_services(mixed_data)
      end

      it 'continues importing other recipes' do
        command

        expect(Recipe.count).to eq(2)
      end

      it 'tracks errors for failed recipes' do
        result = command

        expect(result.stats[:errors].length).to eq(1)
        expect(result.stats[:errors].first[:error]).to include("Validation failed")
      end

      it 'tracks successful imports correctly' do
        expect(command.stats[:recipes]).to eq(2)
      end
    end

    context 'with time and rating parsing' do
      let(:json_data) do
        [
          {
            "title" => "Test Recipe",
            "cook_time" => "30",
            "prep_time" => "15",
            "ingredients" => [ "flour" ],
            "ratings" => "4.75",
            "category" => "Desserts",
            "author" => "Test Chef"
          }
        ]
      end

      it 'parses cook_time correctly' do
        command

        expect(Recipe.first.cook_time).to eq(30)
      end

      it 'parses prep_time correctly' do
        command

        expect(Recipe.first.prep_time).to eq(15)
      end

      it 'parses ratings correctly' do
        command

        expect(Recipe.first.ratings).to eq(4.75)
      end

      context 'with nil times' do
        before do
          modified_data = [
            {
              "title" => "Test Recipe",
              "cook_time" => nil,
              "prep_time" => nil,
              "ingredients" => [ "flour" ],
              "ratings" => "4.75",
              "category" => "Desserts",
              "author" => "Test Chef"
            }
          ]
          stub_services(modified_data)
        end

        it 'handles nil times' do
          command

          expect(Recipe.count).to eq(1)
          expect(Recipe.first.cook_time).to eq(0)
          expect(Recipe.first.prep_time).to eq(0)
        end
      end

      context 'with ratings outside valid range' do
        let(:modified_data) do
          [
            {
              "title" => "Test Recipe",
              "cook_time" => "30",
              "prep_time" => "15",
              "ingredients" => [ "flour" ],
              "ratings" => "6.5",
              "category" => "Desserts",
              "author" => "Test Chef"
            }
          ]
        end

        before do
          allow(GzipExtractor).to receive(:call) do
            instance_double(GzipExtractor, success?: true, failure?: false, result: modified_data.to_json)
          end
        end

        it 'handles ratings outside valid range' do
          command

          expect(Recipe.count).to eq(1)
          expect(Recipe.first.ratings).to be_nil
        end
      end
    end

    context 'with large dataset' do
      before do
        large_json_data = 100.times.map do |i|
          {
            "title" => "Recipe #{i}",
            "cook_time" => "#{20 + (i % 10)}",
            "prep_time" => "#{10 + (i % 5)}",
            "ingredients" => [ "ingredient #{i}" ],
            "category" => "Category #{i % 5}",
            "author" => "Author #{i % 10}"
          }
        end
        stub_services(large_json_data)
      end

      it 'imports all recipes' do
        command

        expect(Recipe.count).to eq(100)
      end

      it 'creates correct number of categories' do
        command

        expect(Category.count).to eq(5)
      end

      it 'creates correct number of authors' do
        command

        expect(Author.count).to eq(10)
      end
    end

    context 'with image URL extraction' do
      let(:test_data) do
        [
          {
            "title" => "Test Recipe",
            "cook_time" => "30",
            "prep_time" => "15",
            "ingredients" => [ "flour" ],
            "category" => "Desserts",
            "author" => "Test Chef",
            "image" => image_url
          }
        ]
      end

      before do
        stub_services(test_data)
      end

      context 'when image URL is a proxy URL' do
        let(:image_url) do
          "https://imagesvc.meredithcorp.io/v3/mm/image?url=https%3A%2F%2Fstatic.onecms.io%2Fwp-content%2Fuploads%2Fsites%2F43%2F2021%2F10%2F26%2Fcornbread-1.jpg"
        end

        it 'extracts the actual image URL from the proxy URL' do
          command

          expect(Recipe.first.image_url).to eq("https://static.onecms.io/wp-content/uploads/sites/43/2021/10/26/cornbread-1.jpg")
        end
      end

      context 'when image URL is a direct URL' do
        let(:image_url) { "https://example.com/direct-image.jpg" }

        it 'uses the direct URL as-is' do
          command

          expect(Recipe.first.image_url).to eq("https://example.com/direct-image.jpg")
        end
      end

      context 'when image URL is nil' do
        let(:image_url) { nil }

        it 'handles nil image URL' do
          command

          expect(Recipe.count).to eq(1)
          expect(Recipe.first.image_url).to be_nil
        end
      end

      context 'when image URL is blank' do
        let(:image_url) { "" }

        it 'handles blank image URL' do
          command

          expect(Recipe.count).to eq(1)
          expect(Recipe.first.image_url).to be_nil
        end
      end

      context 'when image URL is malformed' do
        let(:image_url) { "not a valid url at all" }

        it 'uses the original URL when parsing fails' do
          command

          expect(Recipe.count).to eq(1)
          expect(Recipe.first.image_url).to eq("not a valid url at all")
        end
      end

      context 'when proxy URL has no url parameter' do
        let(:image_url) { "https://imagesvc.meredithcorp.io/v3/mm/image?width=300&height=200" }

        it 'uses the original URL when url parameter is missing' do
          command

          expect(Recipe.count).to eq(1)
          expect(Recipe.first.image_url).to eq("https://imagesvc.meredithcorp.io/v3/mm/image?width=300&height=200")
        end
      end
    end
  end
end
