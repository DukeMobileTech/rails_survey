FactoryBot.define do
  factory :instrument do
    sequence(:title) { |n| "instrument #{n}" }
    language { 'en' }
    alignment { 'left' }
    project
    published { true }
  end
end
