class AddIdToStudentPaymentMethods < ActiveRecord::Migration[7.0]
  def change
    add_column :student_payment_methods, :id, :primary_key
  end
end
