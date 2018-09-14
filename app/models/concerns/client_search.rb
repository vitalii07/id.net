module ClientSearch
  extend ActiveSupport::Concern

   included do
    include ElasticsearchSupport

    if Rails.env.test?
      index_name 'test-client'
    end

    self::ES_OPTIONS = {
      analysis: {
        filter: {
          full_name: {
            type: 'nGram',
            min_gram: 3,
            max_gram: 20
          }
        },
        analyzer: {
          name_analyzer: {
            type: :custom,
            tokenizer: 'keyword',
            filter: ['lowercase','full_name']
          }
        }
      }
    }

    settings self::ES_OPTIONS do
      mapping dynamic: false do
        indexes :id,                          type: 'string', index: 'not_analyzed'
        indexes :status,                      type: 'string', index: 'not_analyzed'
        indexes :display_name,                type: 'string', analyzer: 'name_analyzer'
        indexes :game_center_tos_accepted_at, type: 'date'
        indexes :is_released, type: 'boolean'
        indexes :studio_name,                 type: 'string', analyzer: 'name_analyzer'
        indexes :with_scores?, type: 'boolean'
        indexes :with_cheats?, type: 'boolean'
        indexes :score_type,                  type: 'string', index: 'not_analyzed'
      end
    end
  end

  module ClassMethods
    # options may have keys:
    # - display_name: application name
    def admin_search(params={})
      params = params.with_indifferent_access
      filters = params.slice(:client_id, :display_name, :is_released, :studio_name, :with_highscores, :with_cheats).reject{|k| params[k].blank? }
      musts = []
      if !filters.blank?
        musts << { term: {_id: filters[:client_id].downcase} } if filters[:client_id].present?
        musts << { term: {display_name: filters[:display_name].downcase} } if filters[:display_name].present?
        musts << { term: {is_released: filters[:is_released]}} if filters[:is_released].present? && filters[:is_released] != 'all'
        musts << { term: {studio_name: filters[:studio_name].downcase} } if filters[:studio_name].present?
        musts << { term: {with_scores?: filters[:with_highscores]}} if filters[:with_highscores].present? && filters[:with_highscores] != 'all'
        musts << { term: {with_cheats?: filters[:with_cheats]}} if filters[:with_cheats].present? && filters[:with_cheats] != 'all'
      end

      if params[:state].present? && params[:state] != 'all'
        musts << { term: {status: params[:state] }}
      else
        musts << { terms: {status: %w{ pending accepted rejected } }}
      end

      if params[:account_email].present?
        account = Account.any_of(email: params[:account_email]).first
        if account
          musts << { term: {account_id: account.id}}
        else
          return []
        end
      end

      query = {
        query: {
          bool: {
            must: musts
          }
        },
        sort: { game_center_tos_accepted_at: { order: 'desc'} }
      }

      results = __elasticsearch__.search(query).page(params[:page]).per(params[:per] || 50)
      results.records
    end
  end

  def as_indexed_json(options = {})
    as_json(
      options.merge(methods: [:display_name, :with_scores?, :with_cheats?, :score_type])
    )
  end

  def to_indexed_json(options = {})
    as_indexed_json(options).to_json
  end

  def display_name
    self.display_name # see the display_name method in client.rb
  end

  def with_scores?
    self.with_scores?
  end

  def with_cheats?
    self.with_cheats?
  end

  def score_type
    self.score_type
  end
end
