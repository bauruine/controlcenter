require 'spec_helper'

RSpec.describe UsersController, type: :controller do
  describe "login mechanism" do

    it "should get forward to login when not logged in" do
      get :index
      assert_redirected_to :login
    end
  end
end
