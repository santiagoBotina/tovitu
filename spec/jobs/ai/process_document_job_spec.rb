require "rails_helper"

RSpec.describe Ai::ProcessDocumentJob do
  let(:shelter) { create(:shelter) }
  let(:fake_embedding) { Array.new(1536) { rand(-0.1..0.1) } }

  before do
    stub_embedding_adapter(return_value: [ fake_embedding ] * 3)
  end

  describe "#perform" do
    context "with a manual document" do
      let(:document) do
        create(:ai_document, shelter: shelter, status: "processing",
               source_type: "manual",
               content: "First paragraph about adoption fees.\n\nSecond paragraph about home visits.\n\nThird paragraph about required documents.")
      end

      it "chunks the content and creates embeddings" do
        expect(Ai::Rag::Chunker).to receive(:call).with(document.content)
          .and_call_original

        described_class.new.perform(document.id)
      end

      it "creates document chunks" do
        expect {
          described_class.new.perform(document.id)
        }.to change(Ai::DocumentChunk, :count).by_at_least(1)
      end

      it "sets status to ready on success" do
        described_class.new.perform(document.id)

        expect(document.reload.status).to eq("ready")
        expect(document.error_message).to be_nil
      end

      it "creates chunks with correct ordering" do
        described_class.new.perform(document.id)

        chunks = document.reload.chunks.order(:chunk_index)
        expect(chunks.first.chunk_index).to eq(0)
        expect(chunks.second.chunk_index).to eq(1) if chunks.size > 1
      end

      it "stores embeddings on each chunk" do
        described_class.new.perform(document.id)

        document.reload.chunks.each do |chunk|
          expect(chunk.embedding).to be_present
        end
      end

      it "uses a transaction" do
        expect(ApplicationRecord).to receive(:transaction).at_least(:once).and_call_original
        described_class.new.perform(document.id)
      end
    end

    context "with a PDF document" do
      let(:document) do
        create(:ai_document, shelter: shelter, status: "processing",
               source_type: "pdf",
               content: "Initial placeholder content")
      end

      before do
        document.file.attach(
          io: StringIO.new("fake pdf bytes"),
          filename: "policy.pdf",
          content_type: "application/pdf"
        )

        allow_any_instance_of(ActiveStorage::Blob).to receive(:download).and_return("fake pdf bytes")

        page_double = instance_double("PDF::Reader::Page", text: "Extracted text from PDF about shelter policies.")
        reader_double = instance_double("PDF::Reader", pages: [ page_double ])
        allow(PDF::Reader).to receive(:new).and_return(reader_double)

        allow(Ai::Rag::Chunker).to receive(:call).and_return([
          { content: "Extracted text from PDF about shelter policies.", index: 0, metadata: {} }
        ])
        allow(Ai::Rag::EmbeddingService).to receive(:call).and_return([ [ 0.1 ] * 1536 ])
      end

      it "extracts text from the PDF" do
        expect_any_instance_of(ActiveStorage::Blob).to receive(:download).and_return("fake pdf bytes")

        described_class.new.perform(document.id)
      end

      it "updates the document content with extracted text" do
        described_class.new.perform(document.id)

        expect(document.reload.content).to eq("Extracted text from PDF about shelter policies.")
      end

      it "sets status to ready on success" do
        described_class.new.perform(document.id)

        expect(document.reload.status).to eq("ready")
      end

      it "creates chunks from the extracted text" do
        described_class.new.perform(document.id)

        expect(document.reload.chunks).to be_present
      end
    end

    context "status handling" do
      let(:document) do
        create(:ai_document, shelter: shelter, status: "processing",
               source_type: "manual",
               content: "Policy content.")
      end

      it "only processes documents with processing status" do
        document.update!(status: "ready")
        expect(Ai::Rag::Chunker).not_to receive(:call)

        described_class.new.perform(document.id)
        expect(document.reload.status).to eq("ready")
      end

      it "sets status to failed on error" do
        allow(Ai::Rag::Chunker).to receive(:call).and_raise(StandardError.new("Chunking failed"))

        expect {
          described_class.new.perform(document.id)
        }.to raise_error(StandardError, "Chunking failed")

        expect(document.reload.status).to eq("failed")
        expect(document.reload.error_message).to eq("Chunking failed")
      end

      it "re-raises the error after marking as failed" do
        allow(Ai::Rag::Chunker).to receive(:call).and_raise(StandardError.new("Boom"))

        expect {
          described_class.new.perform(document.id)
        }.to raise_error(StandardError, "Boom")
      end
    end

    context "with a document that has no chunks content" do
      let(:document) do
        create(:ai_document, shelter: shelter, status: "processing",
               source_type: "manual", content: "placeholder").tap do |doc|
          doc.update_column(:content, "")
        end
      end

      it "still processes and marks as ready" do
        described_class.new.perform(document.id)

        expect(document.reload.status).to eq("ready")
      end
    end
  end
end
