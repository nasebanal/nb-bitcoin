require "spec_helper"

describe HomeController do

	render_views

	context "GET index" do

		before(:each) do
			get :index
		end

		it {expect(response).to have_http_status(:success)}
	end
end
