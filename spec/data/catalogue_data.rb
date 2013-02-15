SpecData.define(:catalogue) do
  reds = create(:product_category, :name => 'Red')
  
  create(:product, :name => "Executioner's Block SVG", :category => reds) do |w|
    w.skus << build(:sku, :name => '2012', :price => '29.90')
    w.skus << build(:sku, :name => '2011', :price => '37.90')
  end

  create(:product, :name => "Terminus Est Syrah", :category => reds) do |w|
    w.skus << build(:sku, :name => '2011', :price => '49.90')
    w.skus << build(:sku, :name => '2010', :price => '79.90')
  end

  create(:product, :name => "Agnus Dei MMM", :category => reds, :status => 'not_for_sale') do |w|
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

