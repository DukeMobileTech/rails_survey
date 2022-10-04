class AddVersionNameToDeviceSyncEntries < ActiveRecord::Migration[4.2]
  def change
    rename_column :device_sync_entries, :current_version, :current_version_code
    add_column :device_sync_entries, :current_version_name, :string
  end
end
