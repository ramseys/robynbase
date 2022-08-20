# frozen_string_literal: true

class RenameAuthorizedUnauthorizedReleaseTypes < ActiveRecord::Migration[7.0]
  def up
    Composition.where(type: "Authorized").update_all(type: "Album")
    Composition.where(type: "Unauthorized").update_all(type: "Bootleg")
  end

  def down
    Composition.where(type: "Album").update_all(type: "Authorized")
    Composition.where(type: "Bootleg").update_all(type: "Unauthorized")
  end

end
