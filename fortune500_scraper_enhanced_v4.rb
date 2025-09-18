require 'selenium-webdriver'
require 'nokogiri'
require 'httparty'
require 'csv'
require 'logger'
require 'fileutils'
require 'uri'

class Fortune500Scraper
  BASE_URL = "https://fortune.com"
  LOGGER = Logger.new($stdout)

  def initialize(headless: true)
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless') if headless
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-gpu')
    options.add_argument('--window-size=1920,1080')
    @driver = Selenium::WebDriver.for :chrome, options: options
  end

  def load_page(url)
    LOGGER.info "Loading page: #{url}"
    @driver.navigate.to(url)
    sleep 3
    doc = Nokogiri::HTML(@driver.page_source)
    doc
  end

  def extract_companies(doc)
    companies = []
    table = doc.css("table").first
    return [] unless table

    table.css("tr").each_with_index do |row, idx|
      cells = row.css("td, th")
      next if cells.size < 2
      name = cells[1].text.strip rescue nil
      next unless name && name.length > 1
      link = cells[1].css("a").first&.[]("href")
      detail_url = link ? URI.join(BASE_URL, link).to_s : nil
      companies << { rank: idx, company_name: name, detail_url: detail_url }
    end

    LOGGER.info "Extracted #{companies.size} companies"
    companies
  end

  def extract_website(detail_url)
    return nil unless detail_url
    @driver.navigate.to(detail_url)
    sleep 2
    doc = Nokogiri::HTML(@driver.page_source)

    # Try to locate "Website:" label
    website = nil
    doc.css("a").each do |a|
      href = a["href"]
      next unless href&.start_with?("http")
      next if href.include?("fortune.com") || href =~ /(facebook|twitter|linkedin|instagram)/
      website = href
      break
    end
    website
  end

  def scrape(year: nil, max_companies: 10)
    url = year ? "#{BASE_URL}/ranking/fortune500/#{year}/" : "#{BASE_URL}/ranking/fortune500/"
    doc = load_page(url)
    companies = extract_companies(doc)

    companies = companies.take(max_companies) if max_companies
    companies.each do |company|
      LOGGER.info "Getting website for #{company[:company_name]}"
      company[:website] = extract_website(company[:detail_url])
    end

    save_to_csv(companies)
  ensure
    @driver.quit
  end

  def save_to_csv(companies, filename = "fortune500_ruby.csv")
    FileUtils.mkdir_p("data")
    filepath = File.join("data", filename)
    CSV.open(filepath, "w") do |csv|
      csv << ["Rank", "Company", "Detail URL", "Website"]
      companies.each do |c|
        csv << [c[:rank], c[:company_name], c[:detail_url], c[:website]]
      end
    end
    LOGGER.info "Saved #{companies.size} companies to #{filepath}"
  end
end

# Run script
if __FILE__ == $0
  scraper = Fortune500Scraper.new(headless: true)
  scraper.scrape(year: 2025, max_companies: 10) # test with 10 companies
end
