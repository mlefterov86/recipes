require "open-uri"
require "tempfile"

class FileDownloader
  prepend ServiceObject

  attr_reader :url, :destination

  def initialize(url:, destination:)
    @url = url
    @destination = destination
  end

  def call
    create_directory

    # Download to temporary file first
    temp_file = download_to_temp_file

    # Check if destination exists and compare sizes
    if File.exist?(destination)
      temp_size = File.size(temp_file.path)
      existing_size = File.size(destination)

      if temp_size == existing_size
        # Files are the same size, remove temp and keep existing
        temp_file.close
        temp_file.unlink

        return destination
      end
    end

    # Files are different sizes or destination doesn't exist, replace with new file
    temp_file.close
    FileUtils.mv(temp_file.path, destination)

    destination
  rescue OpenURI::HTTPError => e
    abort(:download, :http_error, "Failed to download file from #{url}: #{e.message}")
  rescue StandardError => e
    abort(:download, :failed, "Download failed: #{e.message}")
  end

  private

  def create_directory
    FileUtils.mkdir_p(File.dirname(destination))
  end

  def download_to_temp_file
    temp_file = Tempfile.new([ "download", File.extname(destination) ])

    URI.open(url) do |remote_file|
      temp_file.binmode
      temp_file.write(remote_file.read)
      temp_file.flush
    end

    temp_file
  end
end
