require 'spec_helper'

describe "Public" do 
  describe "Catalogue browsing" do
    before(:all) do 
      reds = create(:product_category, :name => 'Red')
      
      create(:product, :name => "Executioner's Block SVG", :category => reds) do |w|
        w.skus << build(:sku, :name => '2012', :price => '29.90')
        w.skus << build(:sku, :name => '2011', :price => '37.90')
      end

      create(:product, :name => "Terminus Est Syrah", :category => reds) do |w|
        w.skus << build(:sku, :name => '2011', :price => '49.90')
        w.skus << build(:sku, :name => '2010', :price => '79.90')
      end

      whites = create(:product_category, :name => 'White')

      create(:product, :name => "Extra Wooded Chardonnay", :category => whites) do |w|
        w.skus << build(:sku, :name => '2012', :price => '19.90')
        w.skus << build(:sku, :name => '2011', :price => '17.90')
      end

      create(:product, :name => "Really Really Riesling", :category => whites) do |w|
        w.skus << build(:sku, :name => '2011', :price => '19.90')
        w.skus << build(:sku, :name => '2010', :price => '19.90')
      end
    end

    it "should render index with content" do
      visit '/catalogue'
      expect(page).to have_selector('h1', :text => 'Product Catalogue')

      categories = first('[rel=product-categories]')
      
      expect(categories).to have_selector('a', :text => 'Red')
      expect(categories).to have_selector('a', :text => 'White')

      newest = first('[rel=newest-products]')

      expect(newest).to have_selector('a', :text => "Executioner's Block SVG")
      expect(newest).to have_selector('a', :text => "Terminus Est Syrah")
      expect(newest).to have_selector('a', :text => "Extra Wooded Chardonnay")
      expect(newest).to have_selector('a', :text => "Really Really Riesling")
    end
  end
end

