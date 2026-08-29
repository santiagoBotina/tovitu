module Pets
  # Shared column and value metadata for the batch pet import. Spreadsheet
  # values are normalized (types + enums) through this module; the parser
  # handles file structure and the processor handles per-row creation.
  module Import
    # Marker for "column present in the cell but blank → skip the attribute".
    SKIP = Object.new.freeze
    # Marker for "column present with an unparseable value → report a field error".
    INVALID = Object.new.freeze

    REQUIRED_COLUMNS = %w[name species age_category sex].freeze

    IMPORTABLE_STATUSES = (Pet::STATUSES - [ "removed" ]).freeze

    # Raw spreadsheet headers (en + es) mapped to canonical column names.
    COLUMN_ALIASES = {
      "name" => %w[name nombre],
      "species" => %w[species especie],
      "breed" => %w[breed raza],
      "age_category" => %w[age_category age age\ category edad],
      "birth_date" => %w[birth_date birthdate birth\ date fecha\ de\ nacimiento],
      "size" => %w[size tamano tamaño],
      "sex" => %w[sex sexo genero género],
      "status" => %w[status estado],
      "description" => %w[description descripcion descripción],
      "personality_traits" => %w[personality_traits personality personalidad rasgos],
      "medical_notes" => %w[medical_notes medical\ notes medical notas\ medicas notas\ médicas],
      "spayed_neutered" => %w[spayed_neutered spayed/neutered esterilizado castrado],
      "vaccinated" => %w[vaccinated vacunado],
      "special_needs" => %w[special_needs necesidades\ especiales],
      "good_with_children" => %w[good_with_children bueno\ con\ ninos bueno\ con\ niños],
      "good_with_dogs" => %w[good_with_dogs bueno\ con\ perros],
      "good_with_cats" => %w[good_with_cats bueno\ con\ gatos],
      "requirements" => %w[requirements requisitos requerimientos],
      "personality_spec" => %w[personality_spec especificacion\ de\ personalidad],
      "adopter_tips" => %w[adopter_tips consejos]
    }.freeze

    # Canonical column → value definition used by the parser/processor.
    COLUMNS = {
      "name" => { type: :string },
      "species" => { type: :enum, values: Pet::SPECIES, i18n: "pets.species" },
      "breed" => { type: :string },
      "age_category" => { type: :enum, values: Pet::AGE_CATEGORIES, i18n: "pets.age_categories" },
      "birth_date" => { type: :date },
      "size" => { type: :enum, values: Pet::SIZES, i18n: "pets.sizes" },
      "sex" => { type: :enum, values: Pet::SEXES, i18n: "pets.sex" },
      "status" => { type: :enum, values: IMPORTABLE_STATUSES, i18n: "pets.status" },
      "description" => { type: :text },
      "personality_traits" => { type: :list },
      "medical_notes" => { type: :text },
      "spayed_neutered" => { type: :boolean },
      "vaccinated" => { type: :boolean },
      "special_needs" => { type: :boolean },
      "good_with_children" => { type: :boolean },
      "good_with_dogs" => { type: :boolean },
      "good_with_cats" => { type: :boolean },
      "requirements" => { type: :text },
      "personality_spec" => { type: :text },
      "adopter_tips" => { type: :text }
    }.freeze

    TRUE_VALUES = %w[1 true yes y si sí s verdadero].freeze
    FALSE_VALUES = %w[0 false no n na falso].freeze

    module_function

    # Maps a raw spreadsheet header to its canonical column, or nil if unknown.
    def canonical_header(header)
      return nil if header.nil?

      key = normalize_header(header)
      COLUMN_ALIASES.each do |canonical, aliases|
        return canonical if aliases.any? { |alias_value| normalize_header(alias_value) == key }
      end
      nil
    end

    def normalize_header(value)
      value.to_s.strip.downcase.gsub(/[\s_\/]+/, " ").squeeze(" ").strip
    end

    # Normalizes a raw cell value for a canonical column. Returns the value,
    # SKIP (blank → don't set the attribute) or INVALID (present but bad).
    def normalize_value(column, raw)
      definition = COLUMNS[column]
      return SKIP if raw.nil?

      case definition[:type]
      when :string, :text then normalize_text(raw)
      when :list then normalize_list(raw)
      when :boolean then normalize_boolean(raw)
      when :date then normalize_date(raw)
      when :enum then normalize_enum(definition, raw)
      else SKIP
      end
    end

    def normalize_text(raw)
      value = raw.is_a?(String) ? raw.strip : raw.to_s.strip
      value.present? ? value : SKIP
    end

    def normalize_list(raw)
      value = raw.is_a?(String) ? raw.strip : raw.to_s.strip
      return SKIP if value.blank?

      value.split(",").map(&:strip).reject(&:blank?)
    end

    def normalize_boolean(raw)
      value = raw.to_s.strip.downcase
      return SKIP if value.blank?
      return true if TRUE_VALUES.include?(value)
      return false if FALSE_VALUES.include?(value)

      INVALID
    end

    def normalize_date(raw)
      return raw if raw.is_a?(Date)

      value = raw.to_s.strip
      return SKIP if value.blank?

      Date.parse(value)
    rescue ArgumentError, TypeError
      INVALID
    end

    def normalize_enum(definition, raw)
      value = raw.to_s.strip.downcase
      return SKIP if value.blank?
      return value if definition[:values].include?(value)

      # Accept localized labels (en + es) as values.
      definition[:values].each do |candidate|
        [ :en, :es ].each do |locale|
          label = I18n.t("#{definition[:i18n]}.#{candidate}", locale: locale, default: nil)
          return candidate if label && label.downcase == value
        end
      end
      INVALID
    end

    def column_label(column)
      I18n.t("pets.attributes.#{column}", default: column.to_s.titleize)
    end

    def allowed_label(column)
      definition = COLUMNS[column]
      return nil unless definition && definition[:type] == :enum

      definition[:values].map { |value| I18n.t("#{definition[:i18n]}.#{value}") }.join(", ")
    end
  end
end
