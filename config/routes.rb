IslayIntegration::Application.routes.draw do
  mount Islay::Engine => '/'
  mount IslayShop::Engine => '/'
end
