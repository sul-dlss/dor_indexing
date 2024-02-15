# frozen_string_literal: true

class DorIndexing
  module Indexers
    # Indexes the object's state in the most recent execution of every one of its workflows
    class WorkflowsIndexer
      attr_reader :id

      def initialize(id:, workflow_client:, **)
        @id = id
        @workflow_client = workflow_client
      end

      # @return [Hash] the partial solr document for workflows concerns
      def to_solr
        WorkflowSolrDocument.new do |combined_doc|
          workflows.each do |wf|
            doc = WorkflowIndexer.new(workflow: wf, workflow_client:).to_solr
            combined_doc.merge!(doc)
          end
        end.to_h
      end

      private

      attr_reader :workflow_client

      # @return [Array<Workflow::Response::Workflow>]
      def workflows
        all_workflows.workflows
      end

      # @return [Workflow::Response::Workflows]
      def all_workflows
        @all_workflows ||= workflow_client.workflow_routes.all_workflows pid: id
      end
    end
  end
end
