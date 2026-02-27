require 'test_helper'

class ConnectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(User.take)
    @artist_a = artists(:radiohead)
    @artist_b = artists(:thom_yorke)
  end

  # ── show ──

  test 'show renders without params' do
    get connections_path
    assert_response :success
  end

  test 'show renders with valid artist params' do
    get connections_path, params: { artist_a: @artist_a.id, artist_b: @artist_b.id }
    assert_response :success
    assert_select "[data-degrees-artist-a-id-value='#{@artist_a.id}']"
    assert_select "[data-degrees-artist-a-name-value='#{@artist_a.name}']"
    assert_select "[data-degrees-artist-b-id-value='#{@artist_b.id}']"
    assert_select "[data-degrees-artist-b-name-value='#{@artist_b.name}']"
  end

  test 'show renders normally with invalid artist ids' do
    get connections_path, params: { artist_a: 999_999, artist_b: 888_888 }
    assert_response :success
    assert_select '[data-degrees-artist-a-id-value]', false
    assert_select '[data-degrees-artist-b-id-value]', false
  end

  test 'show renders normally with only one artist param' do
    get connections_path, params: { artist_a: @artist_a.id }
    assert_response :success
    assert_select '[data-degrees-artist-a-id-value]', false
  end

  test 'show requires authentication' do
    sign_out
    get connections_path
    assert_redirected_to new_session_path
  end
end
