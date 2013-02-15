FactoryGirl.define do
  factory :product_category do
    published true
    status 'for_sale'
    description Faker::Lorem.paragraphs
  end
end
