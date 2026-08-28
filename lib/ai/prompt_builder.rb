module Ai
  class PromptBuilder < ApplicationService
    PROMPTS_DIR = Rails.root.join("config/prompts")

    def initialize(prompt_name:, variables: {})
      @prompt_name = prompt_name
      @variables = variables
      super()
    end

    def call
      template = load_template
      interpolate(template)
    end

    # Public interpolation helper so callers can apply the same {{variable}}
    # substitution to other templates (e.g. the system prompt) that are not
    # loaded through PromptBuilder itself.
    def self.interpolate(template, variables)
      variables.reduce(template) do |result, (key, value)|
        result.gsub("{{#{key}}}", value.to_s)
      end
    end

    private

    attr_reader :prompt_name, :variables

    def load_template
      path = PROMPTS_DIR.join("#{prompt_name}.yml")
      raise "Prompt template not found: #{path}" unless path.exist?

      YAML.load_file(path).dig("prompt")
    end

    def interpolate(template)
      self.class.interpolate(template, variables)
    end
  end
end
