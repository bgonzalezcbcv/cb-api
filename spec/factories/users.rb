FactoryBot.define do
  factory :user do
    ci { Faker::Number.number(digits: 8) }
    name { Faker::Movies::LordOfTheRings.character }
    surname { Faker::Name.last_name }
    birthdate { Date.today }
    address { Faker::Address.street_address }
    email { Faker::Internet.email }
    password { Faker::Internet.password }
    password_confirmation { password }

    trait :with_invalid_data do
      ci { Faker::Number.number(digits: 3) }
      name = nil
    end

    trait :with_group do
      after(:create){ |user| FactoryBot.create(:user_group, :teacher, :with_group, user_id: user.id) }
    end

    after(:create) { |user| user.add_role(:teacher) }

    trait :with_document do
      documents { FactoryBot.create_list(:document, 1) }
    end
  end
end
