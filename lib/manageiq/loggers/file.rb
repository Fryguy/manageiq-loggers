module ManageIQ
  module Loggers
    class File < Base
      def contents(line_count = 1_000)
        return [] unless logdev&.filename && ::File.exist?(logdev.filename)

        tail(line_count)
          .select { |line| line&.unpack("U*") rescue nil }
          .map { |line| line.force_encoding("utf-8") }
      end

      private

      def tail(line_count)
        lines = []

        ::File.open(logdev.filename, 'r') do |file|
          # Start from the end of the file
          file.seek(0, IO::SEEK_END)
          file_size = file.pos

          # If file is empty, return empty array
          return [] if file_size.zero?

          buffer_size = 8_192
          position = file_size

          # Read backwards in chunks until we have enough lines
          while position > 0 && lines.size < line_count
            # Calculate how much to read
            chunk_size = [buffer_size, position].min
            position -= chunk_size

            # Seek to position and read chunk
            file.seek(position, IO::SEEK_SET)
            chunk = file.read(chunk_size)

            # Split into lines and prepend to our lines array
            chunk_lines = chunk.split("\n")

            # If we're not at the start of the file, the first line might be partial
            if position > 0 && !lines.empty?
              lines[0] = chunk_lines.pop + lines[0]
            end

            lines = chunk_lines + lines
          end
        end

        lines.last(line_count)
      end
    end
  end
end
