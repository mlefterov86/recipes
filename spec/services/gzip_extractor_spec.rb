require 'rails_helper'

RSpec.describe GzipExtractor, type: :service do
  subject(:service) { described_class.call(source: source, destination: destination) }

  let(:source) { Rails.root.join('tmp', 'test-gzip', 'test-file.txt.gz') }
  let(:destination) { Rails.root.join('tmp', 'test-gzip', 'extracted', 'test-file.txt') }
  let(:original_content) { 'Hello, World! This is test content.' }

  after do
    # Clean up any created files and directories
    FileUtils.rm_rf(Rails.root.join('tmp', 'test-gzip'))
  end

  describe '#call' do
    it 'extracts the file successfully' do
      FileUtils.mkdir_p(File.dirname(source))
      create_gzip_file(source, original_content)

      expect(service).to be_success
      expect(service.result).to eq(original_content)
      expect(File.exist?(destination)).to be true
      expect(File.read(destination)).to eq(original_content)
    end

    it 'creates parent directories if they do not exist' do
      FileUtils.mkdir_p(File.dirname(source))
      create_gzip_file(source, original_content)

      expect(service).to be_success
      expect(File.directory?(File.dirname(destination))).to be true
    end

    it 'handles empty gzip file' do
      FileUtils.mkdir_p(File.dirname(source))
      create_gzip_file(source, '')

      expect(service).to be_success
      expect(File.read(destination)).to eq('')
    end

    it 'handles large gzip files' do
      large_content = 'A' * 1_000_000
      FileUtils.mkdir_p(File.dirname(source))
      create_gzip_file(source, large_content)

      expect(service).to be_success
      expect(File.size(destination)).to eq(1_000_000)
    end

    it 'uses Zlib::GzipReader for extraction' do
      FileUtils.mkdir_p(File.dirname(source))
      create_gzip_file(source, original_content)

      expect(Zlib::GzipReader).to receive(:open).and_call_original

      service
    end

    it 'handles files with special characters' do
      special_content = "Line 1\nLine 2\tTabbed\r\nWindows line\n\nDouble newline"
      FileUtils.mkdir_p(File.dirname(source))
      create_gzip_file(source, special_content)

      expect(service).to be_success
      expect(File.read(destination)).to eq(special_content)
    end

    it 'handles JSON content' do
      json_content = '{"name":"Test","data":[1,2,3],"nested":{"key":"value"}}'
      FileUtils.mkdir_p(File.dirname(source))
      create_gzip_file(source, json_content)

      expect(service).to be_success
      expect(File.read(destination)).to eq(json_content)
      expect { JSON.parse(File.read(destination)) }.not_to raise_error
    end

    context 'when extracting to deeply nested directories' do
      let(:destination) { Rails.root.join('tmp', 'test-gzip', 'deep', 'nested', 'path', 'file.txt') }

      before do
        FileUtils.mkdir_p(File.dirname(source))
        create_gzip_file(source, original_content)
      end

      it 'creates all parent directories' do
        expect(service).to be_success
        expect(File.exist?(destination)).to be true
        expect(File.directory?(File.dirname(destination))).to be true
      end
    end

    context 'when destination already exists' do
      before do
        FileUtils.mkdir_p(File.dirname(source))
        create_gzip_file(source, original_content)
        FileUtils.mkdir_p(File.dirname(destination))
        File.write(destination, 'Old content')
      end

      it 'overwrites the existing file' do
        expect(service).to be_success
        expect(File.read(destination)).to eq(original_content)
        expect(File.read(destination)).not_to eq('Old content')
      end
    end

    context 'when source file does not exist' do
      let(:source) { Rails.root.join('tmp', 'test-gzip', 'nonexistent.gz') }

      it 'aborts with failed error' do
        expect(service).to be_failure
        expect(service.errors.as_key).to eq(:extraction_failed)
        expect(service.errors.message).to include('Extraction failed')
      end

      it 'does not create the destination file' do
        service

        expect(File.exist?(destination)).to be false
      end
    end

    context 'when source is not a valid gzip file' do
      before do
        FileUtils.mkdir_p(File.dirname(source))
        File.write(source, 'This is not gzip content')
      end

      it 'aborts with gzip_error' do
        expect(service).to be_failure
        expect(service.errors.as_key).to eq(:extraction_gzip_error)
        expect(service.errors.message).to include('Failed to extract gzip file')
      end

      it 'does not create the destination file' do
        service

        expect(File.exist?(destination)).to be false
      end
    end

    context 'with different file extensions' do
      let(:source) { Rails.root.join('tmp', 'test-gzip', 'archive.tar.gz') }
      let(:destination) { Rails.root.join('tmp', 'test-gzip', 'extracted', 'archive.tar') }

      before do
        FileUtils.mkdir_p(File.dirname(source))
        create_gzip_file(source, original_content)
      end

      it 'handles .tar.gz files' do
        expect(service).to be_success
        expect(File.exist?(destination)).to be true
      end

      context 'when destination has no extension' do
        let(:destination) { Rails.root.join('tmp', 'test-gzip', 'extracted', 'output') }

        it 'handles files without extensions' do
          expect(service).to be_success
          expect(File.exist?(destination)).to be true
        end
      end
    end
  end

  private

  def create_gzip_file(path, content)
    Zlib::GzipWriter.open(path) do |gz|
      gz.write(content)
    end
  end
end
