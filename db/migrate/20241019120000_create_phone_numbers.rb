class CreatePhoneNumbers < ActiveRecord::Migration[7.0]
  def change
    create_table :phone_numbers do |t|
      t.string :number, null: false
      t.integer :status, default: 0, null: false
      t.text :notes

      t.timestamps
    end

    add_index :phone_numbers, :number, unique: true
  end
end
