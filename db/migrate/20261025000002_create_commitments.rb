class CreateCommitments < ActiveRecord::Migration[8.0]
  def change
    create_table :commitments do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :interval_minutes, null: false, default: 120
      t.boolean :active, null: false, default: true
      t.datetime :next_due_at, null: false
      t.timestamps
    end
    add_index :commitments, [ :active, :next_due_at ]
    add_check_constraint :commitments, "interval_minutes BETWEEN 1 AND 1440", name: "commitment_interval_range"

    create_table :check_ins do |t|
      t.references :commitment, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.datetime :due_at, null: false
      t.datetime :responded_at
      t.timestamps
    end
    add_index :check_ins, :commitment_id, unique: true, where: "status IN ('pending', 'snoozed')", name: "one_open_check_in_per_commitment"
    add_check_constraint :check_ins, "status IN ('pending', 'snoozed', 'done', 'skipped', 'canceled')", name: "check_in_status_values"
  end
end
