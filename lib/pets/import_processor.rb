require "set"

module Pets
  # Creates pets from parsed import rows. Each row is validated against a fresh
  # Pet (all model validations apply) and saved on its own, so a bad row never
  # creates a partial/corrupt pet while valid rows still import. Duplicates are
  # skipped by natural key (name + species + birth_date) both within the file
  # and against the shelter's existing pets, and reported in the summary.
  class ImportProcessor < ApplicationService
    def initialize(shelter:, user:, rows:)
      @shelter = shelter
      @user = user
      @rows = rows
    end

    def call
      imported = []
      duplicates = []
      errors = []
      seen_keys = Set.new
      existing_keys = build_existing_keys

      @rows.each do |row|
        attrs, field_errors = normalize_row(row[:values])
        name = display_name(attrs, row)

        missing = Pets::Import::REQUIRED_COLUMNS.select { |column| attrs[column].blank? }
        missing.each do |column|
          field_errors[column] = [ I18n.t("shelter.pet_imports.errors.required_missing") ]
        end

        if field_errors.any?
          errors << { row: row[:row_number], name: name, fields: field_errors }
          next
        end

        key = natural_key(attrs)
        if seen_keys.include?(key) || existing_keys.include?(key)
          duplicates << { row: row[:row_number], name: name }
          next
        end
        seen_keys << key

        pet = @shelter.pets.new(attrs)
        if pet.valid?
          pet.save!
          existing_keys << key
          imported << { row: row[:row_number], name: pet.name, id: pet.id }
        else
          errors << { row: row[:row_number], name: name, fields: pet.errors.to_hash.transform_keys(&:to_s).transform_values { |msgs| msgs.map(&:to_s) } }
        end
      end

      Result.success(imported: imported, duplicates: duplicates, errors: errors)
    end

    private

    def normalize_row(values)
      attrs = {}
      field_errors = {}
      values.each do |column, raw|
        next unless Pets::Import::COLUMNS.key?(column)

        result = Pets::Import.normalize_value(column, raw)
        if result == Pets::Import::INVALID
          field_errors[column] = [ invalid_message(column) ]
        elsif result != Pets::Import::SKIP
          attrs[column] = result
        end
      end
      [ attrs, field_errors ]
    end

    def invalid_message(column)
      definition = Pets::Import::COLUMNS[column]
      case definition[:type]
      when :boolean
        I18n.t("shelter.pet_imports.errors.invalid_boolean")
      when :date
        I18n.t("shelter.pet_imports.errors.invalid_date")
      else
        allowed = Pets::Import.allowed_label(column)
        if allowed
          I18n.t("shelter.pet_imports.errors.invalid_value", allowed: allowed)
        else
          I18n.t("shelter.pet_imports.errors.invalid_column")
        end
      end
    end

    def display_name(attrs, row)
      attrs["name"].to_s.presence || row[:values]["name"].to_s.presence || I18n.t("shelter.pet_imports.unknown_name")
    end

    def natural_key(attrs)
      parts = [ attrs["name"].to_s.strip.downcase, attrs["species"].to_s ]
      parts << attrs["birth_date"].to_s if attrs["birth_date"].present?
      parts.join("|")
    end

    def build_existing_keys
      @shelter.pets.undiscarded.pluck(:name, :species, :birth_date).map do |name, species, birth_date|
        parts = [ name.to_s.strip.downcase, species.to_s ]
        parts << birth_date.to_s if birth_date.present?
        parts.join("|")
      end.to_set
    end
  end
end
