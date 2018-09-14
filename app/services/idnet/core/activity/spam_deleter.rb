# Deletes old spam
class Idnet::Core::Activity::SpamDeleter
  # @return [void]
  def delete
    threshold = oldness_threshold
    SiteComment.spam.where(:updated_at.lt => threshold).destroy
    es_version = Elasticsearch::Model.client.info['version']['number']
    q = {
      bool: {
        must: [
          {range: {updated_at: { lte: threshold }}},
          {term: {spam_state: 'spam'}}
        ]
      }
    }
    q = es_version >= '1.0' ? {query: q} : q
    query = SiteComment.__elasticsearch__.client.delete_by_query index: SiteComment.index_name, type: SiteComment.document_type, body: q
    SiteComment.__elasticsearch__.refresh_index!
  end

  private
  # @return [Time]
  def oldness_threshold
    Time.now - Idnet.config.application.spam_ttl.hours
  end
end
