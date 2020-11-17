# frozen_string_literal: true

module Sanitizer
  extend ActiveSupport::Concern

  def full_sanitizer
    Rails::Html::FullSanitizer.new
  end

  def safe_list_sanitizer
    Rails::Html::SafeListSanitizer.new
  end

  def html_decode(str)
    HTMLEntities.new.decode(str)
  end
end
