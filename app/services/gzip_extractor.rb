require "zlib"

class GzipExtractor
  prepend ServiceObject

  attr_reader :source, :destination

  def initialize(source:, destination:)
    @source = source
    @destination = destination
  end

  def call
    create_directory

    content = extract_content
    File.write(destination, content)

    content
  rescue Zlib::GzipFile::Error => e
    abort(:extraction, :gzip_error, "Failed to extract gzip file #{source}: #{e.message}")
  rescue StandardError => e
    abort(:extraction, :failed, "Extraction failed: #{e.message}")
  end

  private

  def extract_content
    Zlib::GzipReader.open(source, &:read)
  end

  def create_directory
    FileUtils.mkdir_p(File.dirname(destination))
  end
end
