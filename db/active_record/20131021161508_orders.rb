class Orders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.string :client_id
      t.string :merchant_id
      t.string :account_id
      t.integer :amount
      t.string :currency
      t.string :usage
      t.string :status
      t.string :transaction_id
      t.string :transaction_unique_id
      t.string :card_fingerprint
      t.string :code
      t.string :message

      t.timestamps
    end
  end
end
