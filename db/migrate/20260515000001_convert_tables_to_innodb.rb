class ConvertTablesToInnodb < ActiveRecord::Migration[7.2]
  TABLES = %w[COMP FEG FEGNAME FEGWORD GIG GSET MEDIA MUSO SITE SONG TRAK VENUE XREF] + ["Paste Errors"]

  def up
    TABLES.each do |table|
      execute "ALTER TABLE `#{table}` ENGINE=InnoDB"
    end
  end

  def down
    TABLES.each do |table|
      execute "ALTER TABLE `#{table}` ENGINE=MyISAM"
    end
  end
end
