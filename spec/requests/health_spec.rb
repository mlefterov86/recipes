require 'rails_helper'

RSpec.describe "Health Check", type: :request do
  describe "GET /health" do
    it "returns a successful response" do
      get '/health', headers: { 'Host' => 'test.host' }

      expect(response).to have_http_status(:success)
      expect(response.body).to eq('OK')
    end
  end
end
