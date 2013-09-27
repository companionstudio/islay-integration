IslayIntegration::Application.routes.draw do
  islay_public 'islay_integration' do
    get '/'                   => 'home#index',    :as => 'home'
    get '/shop'               => 'shop#index',    :as => 'shop'
    get '/shop/:id'           => 'shop#product',  :as => 'product'
    get '/shop/category/:id'  => 'shop#category', :as => 'product_category'
    get '/shop/range/:id'     => 'shop#range',    :as => 'product_range'
  end
end
