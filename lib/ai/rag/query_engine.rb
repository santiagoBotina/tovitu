module Ai
  module Rag
    class QueryEngine < ApplicationService
      def initialize(question:, context_chunks:, system_prompt_name: "rag_faq", extra_variables: {})
        @question = question
        @context_chunks = context_chunks
        @system_prompt_name = system_prompt_name
        @extra_variables = extra_variables
        super()
      end

      def call
        prompt = Ai::PromptBuilder.call(
          prompt_name: @system_prompt_name,
          variables: prompt_variables
        )
        Ai::Provider.call(prompt: prompt)
      end

      private

      def prompt_variables
        {
          question: @question,
          context: formatted_context,
          disclaimer: I18n.t("ai.rag.disclaimer")
        }.merge(@extra_variables)
      end

      def formatted_context
        @context_chunks.map.with_index(1) do |chunk, i|
          "[Document #{i}]: #{chunk.content}"
        end.join("\n\n")
      end
    end
  end
end
