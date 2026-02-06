# frozen_string_literal: true

# == Schema Information
#
# Table name: option_sets
#
#  id                          :integer          not null, primary key
#  title                       :string
#  created_at                  :datetime
#  updated_at                  :datetime
#  special                     :boolean          default(FALSE)
#  deleted_at                  :datetime
#  instruction_id              :integer
#  option_in_option_sets_count :integer          default(0)
#

class OptionSet < ActiveRecord::Base
  belongs_to :instruction, optional: true
  has_many :option_in_option_sets, -> { order 'number_in_question' }, dependent: :destroy
  has_many :options, through: :option_in_option_sets
  has_many :translations, through: :options
  has_many :back_translations, through: :translations
  has_many :questions, dependent: :nullify
  has_many :option_set_translations

  has_paper_trail
  acts_as_paranoid

  after_save :set_option_specialty, if: proc { |option_set| option_set.special_changed? }

  def copy
    new_copy = dup
    new_copy.title = "#{title}_#{Time.now.to_i}"
    new_copy.save!
    option_in_option_sets.each do |oios|
      new_oios = oios.dup
      new_oios.option_set_id = new_copy.id
      new_oios.save!
    end
    new_copy
  end

  def self.without_option_in_option_sets
    option_in_option_sets = reflect_on_association(:option_in_option_sets)
    option_in_option_set_arel = option_in_option_sets.klass.arel_table
    option_set_primary_key = arel_table[primary_key]
    option_set_foreign_key = option_in_option_set_arel[option_in_option_sets.foreign_key]
    option_in_option_sets_left_join = arel_table.join(option_in_option_set_arel, Arel::Nodes::OuterJoin)
                                                .on(option_set_primary_key.eq option_set_foreign_key)
                                                .join_sources
    joins(option_in_option_sets_left_join).where(option_in_option_sets.table_name => { option_in_option_sets.klass.primary_key => nil })
  end

  private

  def set_option_specialty
    if special
      option_in_option_sets.update_all(special: true)
    else
      option_in_option_sets.update_all(special: false)
    end
  end
end
