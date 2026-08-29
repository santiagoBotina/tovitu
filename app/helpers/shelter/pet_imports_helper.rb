class Shelter
  module PetImportsHelper
    def pet_import_status_label(pet_import)
      t("shelter.pet_imports.status.#{pet_import.status}")
    end

    def pet_import_summary_text(pet_import)
      t("shelter.pet_imports.summary.line",
        imported: pet_import.imported_count,
        duplicates: pet_import.duplicate_count,
        errors: pet_import.error_count)
    end
  end
end
