IslayIntegration::Application.routes.draw do
  islay_public 'islay_integration' do
    get '/' => 'home#index', :as => 'home'
  end
end
