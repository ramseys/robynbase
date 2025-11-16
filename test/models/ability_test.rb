require 'test_helper'

class AbilityTest < ActiveSupport::TestCase
  # Guest user (not logged in) abilities
  test "guest user can read all resources" do
    ability = Ability.new(nil)

    assert ability.can?(:read, Song)
    assert ability.can?(:read, Gig)
    assert ability.can?(:read, Venue)
    assert ability.can?(:read, Composition)
    assert ability.can?(:read, User)
  end

  test "guest user cannot create resources" do
    ability = Ability.new(nil)

    assert ability.cannot?(:create, Song)
    assert ability.cannot?(:create, Gig)
    assert ability.cannot?(:create, Venue)
    assert ability.cannot?(:create, Composition)
  end

  test "guest user cannot update resources" do
    ability = Ability.new(nil)
    song = create(:song)
    gig = create(:gig)

    assert ability.cannot?(:update, song)
    assert ability.cannot?(:update, gig)
  end

  test "guest user cannot destroy resources" do
    ability = Ability.new(nil)
    song = create(:song)
    venue = create(:venue)

    assert ability.cannot?(:destroy, song)
    assert ability.cannot?(:destroy, venue)
  end

  # Logged-in user abilities
  test "logged-in user can read all resources" do
    user = create(:user)
    ability = Ability.new(user)

    assert ability.can?(:read, Song)
    assert ability.can?(:read, Gig)
    assert ability.can?(:read, Venue)
    assert ability.can?(:read, Composition)
  end

  test "logged-in user can create all resources" do
    user = create(:user)
    ability = Ability.new(user)

    assert ability.can?(:create, Song)
    assert ability.can?(:create, Gig)
    assert ability.can?(:create, Venue)
    assert ability.can?(:create, Composition)
  end

  test "logged-in user can update all resources" do
    user = create(:user)
    ability = Ability.new(user)
    song = create(:song)
    gig = create(:gig)

    assert ability.can?(:update, song)
    assert ability.can?(:update, gig)
    assert ability.can?(:update, Song)
    assert ability.can?(:update, Gig)
  end

  test "logged-in user can destroy all resources" do
    user = create(:user)
    ability = Ability.new(user)
    venue = create(:venue)
    composition = create(:composition)

    assert ability.can?(:destroy, venue)
    assert ability.can?(:destroy, composition)
    assert ability.can?(:destroy, Venue)
    assert ability.can?(:destroy, Composition)
  end

  test "logged-in user can manage all resources" do
    user = create(:user)
    ability = Ability.new(user)

    assert ability.can?(:manage, Song)
    assert ability.can?(:manage, Gig)
    assert ability.can?(:manage, Venue)
    assert ability.can?(:manage, Composition)
    assert ability.can?(:manage, User)
  end
end
