IslayIntegration::Application.routes.draw do
  mount Islay::Engine => '/'
  mount IslayShop::Engine => '/'

  namespace :public, :path => '' do
    get '' => 'home#index', :as => 'home'
  end
end
