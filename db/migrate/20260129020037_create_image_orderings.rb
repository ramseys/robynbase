class CreateImageOrderings < ActiveRecord::Migration[7.2]
  def change
    create_table :image_orderings do |t|
      t.references :attachment, null: false, index: { unique: true }, foreign_key: { to_table: :active_storage_attachments, on_delete: :cascade }
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    # Create initial ordering records for existing attachments
    reversible do |dir|
      dir.up do
        execute <<-SQL
          INSERT INTO image_orderings (attachment_id, position, created_at, updated_at)
          SELECT id,
                 ROW_NUMBER() OVER (PARTITION BY record_type, record_id, name ORDER BY created_at),
                 NOW(),
                 NOW()
          FROM active_storage_attachments
          WHERE name = 'images'
        SQL
      end
    end
  end
end
