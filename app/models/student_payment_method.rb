class StudentPaymentMethod < ApplicationRecord
  belongs_to :student
  belongs_to :payment_method

  validates :year, presence: true

  validates_uniqueness_of :year, scope: [:student_id, :payment_method_id]

  delegate :method, to: :payment_method, prefix: true

end
