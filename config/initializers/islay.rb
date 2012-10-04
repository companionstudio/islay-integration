Islay::Engine.config.integrate_shop_and_blog = true

ImageAssetProcessor.config do
  version(:large) do |img|
    img.resize!(400, 400)
  end
end

Islay::Engine.content do |c|
  c.page(:home, 'Home') do
    content(:what, 'What What', :markdown)
    features(true)
  end

  c.page(:about, 'About Us') do
    content(:mission, 'Our Mission', :markdown)
    content(:philosophy, 'Philosophy', :markdown)

    page(:history, 'History') do
      content(:header, 'Header Image', :image)
      content(:beginning, 'Humble Beginnings', :markdown)
      content(:expansion, 'Expansions and Aquisitions', :markdown)
    end

    page(:staff, 'Staff') do
      content(:what, 'What What', :text)
    end
  end

  c.page(:contact, 'Contact Us') do
    content(:what, 'What What', :text)
  end

  c.shared(:etc, 'Etc') do
    content(:copyright, 'Copyright', :string)
    content(:terms, 'Terms and Conditions', :markdown)
  end
end
