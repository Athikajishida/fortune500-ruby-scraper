# Fortune 500 Scraper (Ruby)

A Ruby-based web scraper that extracts Fortune 500 company data (name, rank, detail URL, and website) using **Selenium WebDriver** and **Nokogiri**, then saves results into CSV.

---

## 🚀 Features

- Scrapes company names, ranks, and detail pages from [Fortune 500](https://fortune.com/ranking/fortune500/)
- Visits company detail pages to extract official websites
- Supports **different years** (e.g., 2025, 2024, etc.)
- Runs in **headless mode** by default (no browser pop-up)
- Saves results to `data/fortune500_ruby.csv`
- Includes retry + logging support for stability

---

## 📦 Requirements

- **Ruby** >= 3.0
- **Google Chrome** (latest stable)
- **ChromeDriver** matching your Chrome version  
  *(Tip: install via Homebrew → `brew install chromedriver`)*

### Gems

Install with Bundler:

```bash
bundle install
```

Gems used:
- `selenium-webdriver`
- `nokogiri`
- `httparty`
- `csv`
- `logger`

---

## ▶️ Usage

Run the scraper:

```bash
ruby fortune500_scraper_enhanced_v4.rb
```

Scrape Fortune 500 (default: 2025, first 10 companies for testing):

```bash
ruby fortune500_scraper_enhanced_v4.rb
```

---

## ⚙️ Configuration

Inside the script, you can adjust:

- `year`: → which year's Fortune 500 ranking to scrape
- `max_companies`: → limit for testing (default 10; set to nil for full list)
- `headless`: → set to false if you want to watch the browser

Example:

```ruby
scraper = Fortune500Scraper.new(headless: false)
scraper.scrape(year: 2024, max_companies: 50)
```

---

## 📂 Output

Results are saved into:

```bash
data/fortune500_ruby.csv
```

CSV format:

| Rank | Company | Detail URL | Website |
|------|---------|------------|---------|
| 1 | Walmart | https://fortune.com/company/walmart | https://walmart.com |
| 2 | Amazon | https://fortune.com/company/amazon | https://amazon.com |

---

## 🛠 Development Notes

- The scraper uses Selenium with headless Chrome → some pages may take time to load
- Random delays and retries can be added to mimic human browsing
- For debugging, you can temporarily save raw HTML into a `debug_html/` folder

---

## 🤝 Contributing

1. Fork the repo
2. Create a new branch (`git checkout -b feature-new`)
3. Commit changes (`git commit -m "Add new feature"`)
4. Push to branch (`git push origin feature-new`)
5. Open a Pull Request 🚀

---

## 📜 License

This project is licensed under the MIT License.

---

## ⚡ Next Steps

After adding this README, run:

```bash
git add README.md
git commit -m "Add project README"
git push origin main
```
