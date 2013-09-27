class IslayIntegration::Public::ShopController < Islay::Public::ApplicationController
  include IslayShop::ControllerExtensions::Public
  
  def index
    @products = Product.published.includes(:current_skus)
  end
end
