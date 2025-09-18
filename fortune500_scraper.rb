require 'httparty'
require 'nokogiri'
require 'selenium-webdriver'
require 'logger'
require 'csv'
require 'json'
require 'fileutils'

class Fortune500Scraper
  attr_reader :logger

  def initialize(headless: true)
    @headless = headless
    @logger = Logger.new($stdout)
    @logger.level = Logger::INFO
  end

  def setup_driver
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless') if @headless
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-gpu')
    options.add_argument('--window-size=1920,1080')
    options.add_argument('--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)')

    @driver = Selenium::WebDriver.for :chrome, options: options
    logger.info("Chrome driver initialized")
    true
  rescue => e
    logger.error("Failed to initialize Chrome driver: #{e}")
    false
  end

  def load_full_table(url)
    logger.info("Loading page: #{url}")
    @driver.navigate.to(url)

    wait = Selenium::WebDriver::Wait.new(timeout: 10)
    wait.until { @driver.find_element(:tag_name, 'table') }
    logger.info("Initial table found")

    sleep 3

    # try scrolling instead of load-more button
    5.times do
      @driver.execute_script("window.scrollTo(0, document.body.scrollHeight)")
      sleep 2
    end

    rows = @driver.find_elements(:css, 'table tr')
    logger.info("Final table has #{rows.size} rows")
    true
  rescue => e
    logger.error("Error loading table: #{e}")
    false
  end

  def extract_companies_from_page
    html = @driver.page_source
    save_debug_html(html, "debug_fortune500.html")

    doc = Nokogiri::HTML(html)
    companies = []

    doc.css('table').each do |table|
      rows = table.css('tr')
      next if rows.size < 10

      rank = 1
      rows.each do |row|
        cells = row.css('td, th')
        next if cells.size < 2

        first_cell = cells[0].text.strip
        company_name = nil
        rank_value = nil

        if first_cell.match?(/^\d+$/)
          rank_value = first_cell.to_i
          company_name = cells[1].text.strip
        else
          cells[0..2].each do |cell|
            text = cell.text.strip
            if text =~ /[A-Za-z]/ && !text.include?('%') && !text.include?('$')
              company_name = text
              rank_value = rank
              break
            end
          end
        end

        if company_name && !company_name.empty?
          companies << { rank: rank_value || rank, company_name: company_name }
          rank = (rank_value ? rank_value + 1 : rank + 1)
        end
      end
    end

    # de-duplicate
    companies.uniq! { |c| c[:company_name].downcase }
    logger.info("Extracted #{companies.size} companies")
    companies
  end

  def scrape(year: nil)
    return nil unless setup_driver

    url = year ? "https://fortune.com/ranking/fortune500/#{year}/" : "https://fortune.com/ranking/fortune500/"

    if load_full_table(url)
      companies = extract_companies_from_page
      return companies
    end
  ensure
    @driver.quit if @driver
  end

  def save_to_csv(companies, filename: "fortune500.csv")
    FileUtils.mkdir_p("data")
    path = File.join("data", filename)

    CSV.open(path, "w") do |csv|
      csv << ["rank", "company_name"]
      companies.each do |company|
        csv << [company[:rank], company[:company_name]]
      end
    end

    logger.info("Data saved to #{path}")
    path
  end

  private

  def save_debug_html(content, filename)
    FileUtils.mkdir_p("debug_html")
    path = File.join("debug_html", filename)
    File.write(path, content)
    logger.info("Debug HTML saved: #{path}")
  end
end

# --- Example Usage ---
scraper = Fortune500Scraper.new(headless: true)
companies = scraper.scrape(year: 2025)
if companies
  scraper.save_to_csv(companies, filename: "fortune500_2025.csv")
  puts "First 10 companies:"
  puts companies.first(10).map { |c| "#{c[:rank]} - #{c[:company_name]}" }
else
  puts "Scraping failed"
end
