require "csv"

module Pets
  # Parses an uploaded pet spreadsheet (.csv or .xlsx) into canonical rows.
  # Structure is validated before any row is created: unsupported formats and
  # missing required columns fail here with a single, friendly message; data
  # rows are returned keyed by canonical column for the processor to handle.
  class ImportParser < ApplicationService
    SUPPORTED_EXTENSIONS = %w[.csv .xlsx].freeze

    def initialize(path:, filename:)
      @path = path
      @filename = filename
    end

    def call
      extension = File.extname(@filename.to_s).downcase
      return Result.failure(I18n.t("shelter.pet_imports.errors.format")) unless SUPPORTED_EXTENSIONS.include?(extension)

      parsed = extension == ".xlsx" ? parse_xlsx : parse_csv
      headers = parsed[:headers]

      if headers.all?(&:blank?)
        return Result.failure(I18n.t("shelter.pet_imports.errors.empty_file"))
      end

      missing = missing_required_columns(headers)
      if missing.any?
        names = missing.map { |column| Pets::Import.column_label(column) }
        return Result.failure(I18n.t("shelter.pet_imports.errors.missing_columns", columns: names.join(", ")))
      end

      Result.success(parsed)
    end

    private

    def parse_csv
      content = File.read(@path, mode: "r:bom|utf-8")
      separator = detect_separator(content)
      table = CSV.parse(content, headers: true, skip_blanks: true, col_sep: separator)
      build_rows(table.headers, table)
    end

    def parse_xlsx
      sheet = Roo::Excelx.new(@path).sheet(0)
      headers = sheet.row(1).map { |cell| cell&.to_s&.strip }
      rows = []
      (2..sheet.last_row).each do |row_index|
        raw = sheet.row(row_index)
        next if raw.compact.empty?

        rows << { row_number: row_index, values: header_values(headers, raw) }
      end
      { headers: headers, rows: rows }
    end

    def build_rows(raw_headers, table)
      headers = raw_headers.to_a
      rows = table.each_with_index.map do |row, index|
        { row_number: index + 2, values: header_values(headers, row) }
      end
      { headers: headers, rows: rows }
    end

    def header_values(raw_headers, row)
      values = {}
      raw_headers.each_with_index do |header, index|
        canonical = Pets::Import.canonical_header(header)
        values[canonical] = row[index] if canonical
      end
      values
    end

    def missing_required_columns(headers)
      canonical = headers.filter_map { |header| Pets::Import.canonical_header(header) }
      Pets::Import::REQUIRED_COLUMNS.reject { |column| canonical.include?(column) }
    end

    # A handful of locales export CSV with `;` separators. Prefer `,` unless
    # the header line only contains semicolons.
    def detect_separator(content)
      first_line = content.lines.first.to_s
      first_line.include?(";") && !first_line.include?(",") ? ";" : ","
    end
  end
end
