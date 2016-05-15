require 'test_helper'

class ApplicationControllerTest < ActionController::TestCase
  test "should get index" do
    post :tag, tag: 'casa', access_token: '2019746130.59a3f2b.86a0135240404ed5b908a14c0a2d9402'
    assert_response :success
  end

end
