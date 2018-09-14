# Adds:
#   * methods to recreate and refresh resource search index
#   * example parameter :es that enables automatic index refreshing before
#     example runs
require 'configuration'
module ElasticSearchSupport
  extend ActiveSupport::Concern

  included do
    before do |example|
      if example.metadata[:es]
        # Allow indexing in ES
        Idnet.config.application[:trigger_tire_callbacks] = true
      else
       Idnet.config.application[:trigger_tire_callbacks] = false
      end
    end
  end

  # @param resource_class [Class]
  # @return [void]
  def recreate_resource_search_index!(resource_class)
    resource_class.__elasticsearch__.delete_index!({force: true})
    resource_class.__elasticsearch__.create_index!({force: true})
  end

  def es_version
    Elasticsearch::Model.client.info['version']['number']
  end

  # @param resource_class [Class]
  # @return [void]
  def refresh_resource_search_index!(resource_class)
    if es_version >= "1.0"
      body = { query: {match_all: {}}}
    else
      body = {match_all: {}}
    end
    resource_class.__elasticsearch__.client.delete_by_query index: resource_class.index_name, type: resource_class.document_type, body: body
    resource_class.import
    resource_class.__elasticsearch__.refresh_index!
  end
end
