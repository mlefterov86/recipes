require 'rails_helper'

RSpec.describe FileDownloader, type: :service do
  subject(:service) { described_class.call(url: url, destination: destination) }

  let(:url) { 'https://example.com/test-file.txt' }
  let(:destination) { Rails.root.join('tmp', 'test-downloads', 'test-file.txt') }
  let(:remote_content) { 'Hello, World!' }

  after do
    # Clean up any created files and directories
    FileUtils.rm_rf(Rails.root.join('tmp', 'test-downloads'))
  end

  describe '#call' do
    before do
      stub_request(:get, url).to_return(body: remote_content, status: 200)
    end

    it 'handles empty remote file' do
      stub_request(:get, url).to_return(body: '', status: 200)

      expect(service).to be_success
      expect(File.read(destination)).to eq('')
    end

    it 'handles large files' do
      large_content = 'A' * 1_000_000 # 1MB of content
      stub_request(:get, url).to_return(body: large_content, status: 200)

      expect(service).to be_success
      expect(File.size(destination)).to eq(1_000_000)
    end

    it 'uses temporary files during download' do
      expect(Tempfile).to receive(:new).and_call_original

      service
    end

    context 'when file does not exist' do
      it 'downloads the file successfully' do
        expect(service).to be_success
        expect(service.result).to eq(destination)
        expect(File.exist?(destination)).to be true
        expect(File.read(destination)).to eq(remote_content)
      end

      it 'creates parent directories if they do not exist' do
        expect(service).to be_success
        expect(File.exist?(destination)).to be true
        expect(File.directory?(File.dirname(destination))).to be true
      end
    end

    context 'when file exists with same size' do
      let(:existing_content) { 'Hello, World!' }

      before do
        FileUtils.mkdir_p(File.dirname(destination))
        File.write(destination, existing_content)
      end

      it 'skips download and keeps existing file' do
        original_mtime = File.mtime(destination)
        sleep 0.01 # Ensure time difference if file is modified

        expect(service).to be_success
        expect(service.result).to eq(destination)
        expect(File.mtime(destination)).to eq(original_mtime) # File not modified
        expect(File.read(destination)).to eq(existing_content)
      end

      it 'does not make unnecessary file writes' do
        expect(FileUtils).not_to receive(:mv)

        service
      end
    end

    context 'when file exists with different size' do
      let(:existing_content) { 'Old content' }
      let(:new_content) { 'This is completely new content with different size' }

      before do
        FileUtils.mkdir_p(File.dirname(destination))
        File.write(destination, existing_content)
      end

      it 'downloads and overwrites the file' do
        stub_request(:get, url).to_return(body: new_content, status: 200)

        expect(service).to be_success
        expect(service.result).to eq(destination)
        expect(File.read(destination)).to eq(new_content)
      end

      it 'replaces file when remote is larger' do
        stub_request(:get, url).to_return(body: new_content, status: 200)

        original_size = File.size(destination)

        service

        expect(File.size(destination)).to be > original_size
      end

      it 'replaces file when remote is smaller' do
        File.write(destination, 'Very long content that is much larger than remote')
        stub_request(:get, url).to_return(body: 'Short', status: 200)

        original_size = File.size(destination)

        service

        expect(File.size(destination)).to be < original_size
        expect(File.read(destination)).to eq('Short')
      end
    end

    context 'when download fails' do
      it 'aborts with http_error on HTTP errors' do
        stub_request(:get, url).to_return(status: 404)

        service

        expect(service).to be_failure
        expect(service.errors.as_key).to eq(:download_http_error)
        expect(service.errors.message).to include('Failed to download file')
      end

      it 'aborts with failed error on network errors' do
        stub_request(:get, url).to_raise(SocketError.new('Network unreachable'))

        service

        expect(service).to be_failure
        expect(service.errors.as_key).to eq(:download_failed)
        expect(service.errors.message).to include('Download failed')
      end

      it 'does not create the destination file on failure' do
        stub_request(:get, url).to_return(status: 500)

        service

        expect(File.exist?(destination)).to be false
      end
    end

    context 'with different file extensions' do
      let(:url) { 'https://example.com/archive.tar.gz' }
      let(:destination) { Rails.root.join('tmp', 'test-downloads', 'archive.tar.gz') }

      it 'handles .gz files' do
        expect(service).to be_success
        expect(File.exist?(destination)).to be true
      end

      context 'when files have no extensions' do
        let(:url) { 'https://example.com/README' }
        let(:destination) { Rails.root.join('tmp', 'test-downloads', 'README') }

        it 'handles files without extensions' do
          expect(service).to be_success
          expect(File.exist?(destination)).to be true
        end
      end
    end
  end
end
