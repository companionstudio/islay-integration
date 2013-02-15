require 'spec_helper'

describe "Public" do 
  describe "catalogue" do
    before(:all) do 
      SpecData.run(:catalogue)
    end

    it "should render index with content" do
      visit '/catalogue'
      expect(page).to have_selector('h1', :text => 'Product Catalogue')

      categories = first('[rel=product-categories]')
      
      expect(categories).to have_selector('a', :text => 'Red')
      expect(categories).to have_selector('a', :text => 'White')

      newest = first('[rel=newest-products]')

      expect(newest).to have_selector('a', :text => "Terminus Est Syrah")
      expect(newest).to have_selector('a', :text => "Extra Wooded Chardonnay")
      expect(newest).to have_selector('a', :text => "Really Really Riesling")
      expect(newest).to have_selector('a', :text => "Agnus Dei MMM")
    end

    it 'should render a product for sale' do
      visit '/catalogue/product/executioner-s-block-svg'

      expect(page).to have_selector('h2', :text => "Product: Executioner's Block SVG")
      expect(page).to have_selector('[rel=add-to-cart]')
    end

    it 'should render a product not for sale' do
      visit '/catalogue/product/agnus-dei-mmm'

      expect(page).to have_selector('h2', :text => "Product: Agnus Dei MMM")
      expect(page).to_not have_selector('[rel=add-to-cart]')
    end
  end
end

