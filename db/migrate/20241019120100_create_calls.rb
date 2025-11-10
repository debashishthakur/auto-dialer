class CreateCalls < ActiveRecord::Migration[7.0]
  def change
    create_table :calls do |t|
      t.references :phone_number, null: false, foreign_key: true
      t.string :call_sid
      t.integer :status, default: 0, null: false
      t.integer :duration
      t.text :recording_url
      t.text :voice_script
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :calls, :call_sid, unique: true
  end
end
