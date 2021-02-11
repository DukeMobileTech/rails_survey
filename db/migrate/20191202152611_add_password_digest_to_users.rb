# frozen_string_literal: true

class AddPasswordDigestToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :password_digest, :string unless column_exists?(:users, :password_digest)
  end
end