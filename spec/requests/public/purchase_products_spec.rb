require 'spec_helper'

describe "Purchasing products" do
  describe "Buy a product in stock" do
    it "should render index" do
      get public_catalogue_path
      response.status.should be(200)
    end
  end
end

