class CreateSubgroups < ActiveRecord::Migration[7.0]
  def change
    create_table :subgroups do |t|
      t.string :name
      t.references :Group, null: false, foreign_key: true

      t.timestamps
    end
  end
end