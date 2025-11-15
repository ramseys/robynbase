#!/usr/bin/env ruby
# CDN Cost Calculator for Robyn Hitchcock Database
# Run with: ruby cdn_cost_calculator.rb

require 'io/console'

class CDNCostCalculator
  PROVIDERS = {
    'Backblaze B2 + Cloudflare' => {
      storage_per_gb: 0.006,  # $6/TB = $0.006/GB
      bandwidth_per_gb: 0.0,  # FREE via Cloudflare Bandwidth Alliance
      api_calls_per_10k: 0.004,
      minimum_cost: 0.0,
      notes: 'Zero egress to Cloudflare CDN'
    },
    'Cloudflare R2' => {
      storage_per_gb: 0.015,  # $15/TB
      bandwidth_per_gb: 0.0,  # No egress fees
      api_writes_per_million: 4.50,
      api_reads_per_million: 0.36,
      minimum_cost: 0.0,
      notes: 'No egress fees ever'
    },
    'Linode Object Storage' => {
      storage_per_gb: 0.02,  # $5/250GB tier pricing
      bandwidth_per_gb: 0.005,  # $5/TB after first 1TB free
      minimum_cost: 5.0,  # $5/month minimum
      included_storage_gb: 250,
      included_bandwidth_gb: 1024,
      notes: 'Flat $5/month for 250GB + 1TB bandwidth'
    },
    'DigitalOcean Spaces' => {
      storage_per_gb: 0.02,  # $0.02/GB overage
      bandwidth_per_gb: 0.01,  # $0.01/GB overage
      minimum_cost: 5.0,  # $5/month base
      included_storage_gb: 250,
      included_bandwidth_gb: 1024,
      notes: '$5/month includes 250GB storage + 1TB bandwidth'
    },
    'Bunny CDN Storage' => {
      storage_per_gb: 0.01,  # $10/TB
      bandwidth_per_gb: 0.01,  # $0.01/GB (cheapest tier)
      minimum_cost: 0.0,
      notes: 'Pay-as-you-go, fastest performance'
    },
    'AWS S3 + CloudFront' => {
      storage_per_gb: 0.023,  # $23/TB Standard tier
      bandwidth_per_gb: 0.085,  # $85/TB CloudFront bandwidth
      api_puts_per_1000: 0.005,
      api_gets_per_1000: 0.0004,
      minimum_cost: 0.0,
      notes: 'Most expensive but most features'
    }
  }

  def initialize
    @storage_gb = nil
    @bandwidth_gb = nil
    @api_requests = nil
    @growth_rate = 0
  end

  def run
    display_header
    get_user_inputs
    calculate_and_display_costs
    show_recommendations
  end

  private

  def display_header
    puts "\n" + "="*70
    puts "  CDN COST CALCULATOR - Robyn Hitchcock Database"
    puts "="*70
    puts "\nThis calculator helps you estimate monthly CDN costs based on your usage."
    puts ""
  end

  def get_user_inputs
    puts "Please provide your usage estimates:\n\n"

    @storage_gb = get_number_input(
      "Total asset storage size (GB): ",
      default: 10,
      min: 0.1
    )

    @bandwidth_gb = get_number_input(
      "Monthly bandwidth/transfer (GB): ",
      default: 100,
      min: 0
    )

    @api_requests = get_number_input(
      "Estimated API requests per month (thousands): ",
      default: 10,
      min: 0
    )

    puts "\nOptional: Estimate monthly growth rate (%)? [Enter to skip]: "
    growth_input = STDIN.gets.chomp
    @growth_rate = growth_input.empty? ? 0 : growth_input.to_f

    puts "\n" + "-"*70
  end

  def get_number_input(prompt, default:, min: 0)
    loop do
      print prompt
      print "(default: #{default}) " if default
      input = STDIN.gets.chomp

      value = input.empty? ? default : input.to_f

      if value >= min
        return value
      else
        puts "Please enter a number >= #{min}"
      end
    end
  end

  def calculate_and_display_costs
    puts "\n📊 COST COMPARISON (Monthly)\n\n"

    results = []

    PROVIDERS.each do |name, pricing|
      monthly_cost = calculate_provider_cost(pricing)
      results << {
        name: name,
        cost: monthly_cost,
        pricing: pricing
      }
    end

    # Sort by cost
    results.sort_by! { |r| r[:cost] }

    # Display results
    results.each_with_index do |result, index|
      display_provider_result(result, index + 1)
    end

    # Display 6-month and 12-month projections
    if @growth_rate > 0
      display_growth_projections(results)
    end
  end

  def calculate_provider_cost(pricing)
    # Calculate storage cost
    storage_cost = 0
    if pricing[:included_storage_gb]
      overage = [@storage_gb - pricing[:included_storage_gb], 0].max
      storage_cost = overage * pricing[:storage_per_gb]
    else
      storage_cost = @storage_gb * pricing[:storage_per_gb]
    end

    # Calculate bandwidth cost
    bandwidth_cost = 0
    if pricing[:included_bandwidth_gb]
      overage = [@bandwidth_gb - pricing[:included_bandwidth_gb], 0].max
      bandwidth_cost = overage * pricing[:bandwidth_per_gb]
    else
      bandwidth_cost = @bandwidth_gb * pricing[:bandwidth_per_gb]
    end

    # Calculate API costs (varies by provider)
    api_cost = 0
    if pricing[:api_calls_per_10k]
      api_cost = (@api_requests / 10.0) * pricing[:api_calls_per_10k]
    elsif pricing[:api_writes_per_million]
      # Assume 20% writes, 80% reads
      writes = @api_requests * 0.2
      reads = @api_requests * 0.8
      api_cost = (writes / 1000.0) * pricing[:api_writes_per_million] +
                 (reads / 1000.0) * pricing[:api_reads_per_million]
    elsif pricing[:api_puts_per_1000]
      # Assume 20% PUTs, 80% GETs
      puts_cost = (@api_requests * 0.2) * pricing[:api_puts_per_1000]
      gets_cost = (@api_requests * 0.8) * pricing[:api_gets_per_1000]
      api_cost = puts_cost + gets_cost
    end

    total = storage_cost + bandwidth_cost + api_cost

    # Apply minimum cost if applicable
    [total, pricing[:minimum_cost] || 0].max
  end

  def display_provider_result(result, rank)
    name = result[:name]
    cost = result[:cost]
    pricing = result[:pricing]

    # Add medal for top 3
    medal = case rank
            when 1 then "🥇"
            when 2 then "🥈"
            when 3 then "🥉"
            else "  "
            end

    puts "#{medal} #{rank}. #{name}"
    puts "   Monthly Cost: $#{cost.round(2)}"

    # Show breakdown
    storage_cost = calculate_storage_cost(pricing)
    bandwidth_cost = calculate_bandwidth_cost(pricing)

    puts "   └─ Storage: $#{storage_cost.round(2)} (#{@storage_gb}GB)"
    puts "   └─ Bandwidth: $#{bandwidth_cost.round(2)} (#{@bandwidth_gb}GB)"
    puts "   └─ Note: #{pricing[:notes]}" if pricing[:notes]
    puts ""
  end

  def calculate_storage_cost(pricing)
    if pricing[:included_storage_gb]
      overage = [@storage_gb - pricing[:included_storage_gb], 0].max
      overage * pricing[:storage_per_gb]
    else
      @storage_gb * pricing[:storage_per_gb]
    end
  end

  def calculate_bandwidth_cost(pricing)
    if pricing[:included_bandwidth_gb]
      overage = [@bandwidth_gb - pricing[:included_bandwidth_gb], 0].max
      overage * pricing[:bandwidth_per_gb]
    else
      @bandwidth_gb * pricing[:bandwidth_per_gb]
    end
  end

  def display_growth_projections(results)
    puts "\n" + "="*70
    puts "📈 GROWTH PROJECTIONS (#{@growth_rate}% monthly growth)"
    puts "="*70
    puts ""

    [6, 12].each do |months|
      puts "\n#{months}-Month Projection:\n"

      # Calculate projected usage
      growth_multiplier = (1 + @growth_rate / 100.0) ** months
      projected_storage = @storage_gb * growth_multiplier
      projected_bandwidth = @bandwidth_gb * growth_multiplier

      puts "  Storage: #{projected_storage.round(1)}GB | Bandwidth: #{projected_bandwidth.round(1)}GB\n\n"

      # Calculate costs for each provider
      results.first(3).each do |result|
        pricing = result[:pricing]

        # Temporarily update values
        old_storage = @storage_gb
        old_bandwidth = @bandwidth_gb
        @storage_gb = projected_storage
        @bandwidth_gb = projected_bandwidth

        cost = calculate_provider_cost(pricing)

        # Restore values
        @storage_gb = old_storage
        @bandwidth_gb = old_bandwidth

        puts "  #{result[:name]}: $#{cost.round(2)}/month"
      end
    end
    puts ""
  end

  def show_recommendations
    puts "\n" + "="*70
    puts "💡 RECOMMENDATIONS"
    puts "="*70
    puts ""

    if @storage_gb < 250 && @bandwidth_gb < 1000
      puts "✓ For your usage, Linode Object Storage or DigitalOcean Spaces"
      puts "  offer predictable flat-rate pricing at $5/month."
      puts ""
    end

    if @bandwidth_gb > 1000
      puts "✓ With #{@bandwidth_gb}GB bandwidth, Backblaze B2 + Cloudflare saves"
      puts "  significantly due to free egress via Cloudflare Bandwidth Alliance."
      puts ""
    end

    puts "✓ Best value overall: Backblaze B2 + Cloudflare"
    puts "  (especially as you scale)"
    puts ""
    puts "✓ Easiest migration: Linode Object Storage"
    puts "  (already in your ecosystem)"
    puts ""
    puts "✓ Simplest pricing: Cloudflare R2"
    puts "  (zero egress fees, S3-compatible)"
    puts ""
    puts "="*70
  end
end

# Run the calculator
if __FILE__ == $0
  calculator = CDNCostCalculator.new
  calculator.run
end
