# Migration Guide: Cloudflare R2

**Best for:** Simple pricing, zero egress fees, fast global performance
**Difficulty:** Easy
**Estimated Time:** 1-2 hours
**Monthly Cost:** ~$1.50 for 100GB storage + unlimited bandwidth

---

## Overview

This guide walks you through migrating your Rails ActiveStorage assets from local disk storage to Cloudflare R2 - an S3-compatible object storage with zero egress fees and automatic global distribution.

---

## Prerequisites

- [ ] Cloudflare account with R2 enabled
- [ ] Credit card (R2 requires billing even for free tier)
- [ ] SSH access to your Linode server
- [ ] Database backup (recommended)

---

## Part 1: Cloudflare R2 Setup (20 minutes)

### Step 1: Enable R2 in Cloudflare

1. Log into Cloudflare Dashboard
2. Navigate to **R2** in the left sidebar
3. Click **Purchase R2 Plan** (free tier available - no minimum charges)
4. Accept the terms and enable R2

### Step 2: Create R2 Bucket

1. In R2 section, click **Create bucket**

**Bucket Configuration:**
```
Bucket name: robynbase-assets-production
Location: Automatic (Cloudflare chooses optimal location)
```

2. Click **Create bucket**
3. Save the bucket name: `robynbase-assets-production`

### Step 3: Create R2 API Token

1. Go to **R2** → **Manage R2 API Tokens**
2. Click **Create API token**

**Token Configuration:**
```
Token name: robynbase-rails-app
Permissions:
  - Object Read & Write
Apply to specific bucket: robynbase-assets-production
```

3. Click **Create API Token**

4. **IMPORTANT:** Save these credentials immediately (shown only once):
   - `Access Key ID`
   - `Secret Access Key`
   - `Endpoint URL` (format: `https://<account-id>.r2.cloudflarestorage.com`)

**Example endpoint:** `https://abc123def456.r2.cloudflarestorage.com`

### Step 4: Configure Public Access (Optional but Recommended)

For public asset access via custom domain:

1. Go to your bucket → **Settings**
2. Under **Public Access**, click **Connect Domain**
3. Choose a subdomain (e.g., `assets.yourdomain.com`)
4. Cloudflare will automatically create the DNS record
5. Click **Allow Access**

Now your assets will be accessible at `https://assets.yourdomain.com/...`

---

## Part 2: Rails Application Configuration (30 minutes)

### Step 5: Update Gemfile

The `aws-sdk-s3` gem is already installed for ActiveStorage. Verify in your `Gemfile`:

```ruby
# Gemfile
gem "aws-sdk-s3", require: false
```

If not present, add it and run:
```bash
bundle install
```

### Step 6: Update Storage Configuration

Edit `config/storage.yml`:

```yaml
# config/storage.yml

# Existing local/development storage
local:
  service: Disk
  root: <%= Rails.root.join("tmp/storage") %>

# Existing production disk storage (keep for now during migration)
robyn:
  service: Disk
  root: <%= Rails.root.join("active-storage-files") %>

# NEW: Cloudflare R2 Production Storage
cloudflare_r2:
  service: S3
  access_key_id: <%= ENV['R2_ACCESS_KEY_ID'] %>
  secret_access_key: <%= ENV['R2_SECRET_ACCESS_KEY'] %>
  region: auto  # R2 uses 'auto' for automatic region selection
  bucket: robynbase-assets-production
  endpoint: <%= ENV['R2_ENDPOINT'] %>  # e.g., https://abc123.r2.cloudflarestorage.com
  public: true
  force_path_style: true  # Required for R2
```

**Important:** R2 requires `force_path_style: true` and `region: auto`

### Step 7: Set Environment Variables

**On your Linode server:**

Add to your environment configuration:

```bash
# Cloudflare R2 Credentials
R2_ACCESS_KEY_ID=your_access_key_id_here
R2_SECRET_ACCESS_KEY=your_secret_access_key_here
R2_ENDPOINT=https://your-account-id.r2.cloudflarestorage.com
```

**For Capistrano deployments**, add to `config/deploy/production.rb`:

```ruby
# config/deploy/production.rb
set :default_env, {
  'R2_ACCESS_KEY_ID' => 'your_access_key_id',
  'R2_SECRET_ACCESS_KEY' => 'your_secret_access_key',
  'R2_ENDPOINT' => 'https://your-account-id.r2.cloudflarestorage.com'
}
```

**Alternatively**, use Rails encrypted credentials:

```bash
EDITOR=nano rails credentials:edit --environment production
```

Add:
```yaml
cloudflare_r2:
  access_key_id: your_access_key_id_here
  secret_access_key: your_secret_access_key_here
  endpoint: https://your-account-id.r2.cloudflarestorage.com
```

Then update `storage.yml`:
```yaml
cloudflare_r2:
  service: S3
  access_key_id: <%= Rails.application.credentials.dig(:cloudflare_r2, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:cloudflare_r2, :secret_access_key) %>
  endpoint: <%= Rails.application.credentials.dig(:cloudflare_r2, :endpoint) %>
  region: auto
  bucket: robynbase-assets-production
  public: true
  force_path_style: true
```

### Step 8: Configure Custom Domain URLs (If using custom domain)

If you set up a custom domain (e.g., `assets.yourdomain.com`), create an initializer:

Create `config/initializers/active_storage.rb`:

```ruby
# config/initializers/active_storage.rb

Rails.application.config.after_initialize do
  if Rails.env.production? && Rails.application.config.active_storage.service == :cloudflare_r2

    # Override URL generation to use custom domain
    module ActiveStorageR2CustomUrl
      def url(expires_in: nil, disposition: :inline, filename: nil, **options)
        # Get original R2 URL
        original_url = super

        # Replace R2 endpoint with custom domain
        cdn_url = original_url.gsub(
          %r{https://[a-z0-9]+\.r2\.cloudflarestorage\.com/robynbase-assets-production},
          'https://assets.yourdomain.com'
        )

        cdn_url
      end
    end

    ActiveStorage::Blob.prepend(ActiveStorageR2CustomUrl)
  end
end
```

**Replace** `https://assets.yourdomain.com` with your actual custom domain.

### Step 9: Update Production Environment

Edit `config/environments/production.rb`:

```ruby
# config/environments/production.rb

# Change from :robyn to :cloudflare_r2
config.active_storage.service = :cloudflare_r2

# Keep existing settings
config.assets.compile = false
config.assets.digest = true
```

### Step 10: Configure CORS (If needed)

If your app uploads files directly from browser JavaScript:

1. In Cloudflare R2 dashboard, go to your bucket
2. Click **Settings** → **CORS Policy**
3. Add this JSON configuration:

```json
[
  {
    "AllowedOrigins": [
      "https://yourdomain.com",
      "https://www.yourdomain.com"
    ],
    "AllowedMethods": [
      "GET",
      "PUT",
      "POST",
      "DELETE",
      "HEAD"
    ],
    "AllowedHeaders": [
      "*"
    ],
    "ExposeHeaders": [
      "ETag"
    ],
    "MaxAgeSeconds": 3600
  }
]
```

4. Click **Save**

---

## Part 3: Data Migration (1 hour)

### Step 11: Create Migration Script

Create `lib/tasks/migrate_to_r2.rake`:

```ruby
# lib/tasks/migrate_to_r2.rake

namespace :storage do
  desc "Migrate existing ActiveStorage files to Cloudflare R2"
  task migrate_to_r2: :environment do
    puts "Starting migration of ActiveStorage files to Cloudflare R2..."

    attachments = ActiveStorage::Attachment.includes(:blob).all
    total = attachments.count
    migrated = 0
    errors = []

    puts "Found #{total} attachments to migrate"

    attachments.find_each.with_index do |attachment, index|
      begin
        blob = attachment.blob

        # Skip if already on R2
        if blob.service_name == 'cloudflare_r2'
          puts "[#{index + 1}/#{total}] Skipping #{blob.filename} (already on R2)"
          next
        end

        # Download file from local disk
        file_data = blob.download

        # Upload to R2
        new_blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new(file_data),
          filename: blob.filename,
          content_type: blob.content_type,
          service_name: 'cloudflare_r2'
        )

        # Update attachment to point to new blob
        attachment.update!(blob: new_blob)

        # Delete old blob from disk
        blob.purge

        migrated += 1
        puts "[#{index + 1}/#{total}] ✓ Migrated: #{blob.filename}"

      rescue => e
        error_msg = "Failed to migrate #{blob&.filename}: #{e.message}"
        errors << error_msg
        puts "[#{index + 1}/#{total}] ✗ #{error_msg}"
      end

      # Small delay to avoid rate limiting
      sleep 0.1 if index % 10 == 0
    end

    puts "\n" + "="*60
    puts "Migration complete!"
    puts "Successfully migrated: #{migrated}/#{total}"
    puts "Errors: #{errors.count}"

    if errors.any?
      puts "\nErrors encountered:"
      errors.each { |e| puts "  - #{e}" }
    end
    puts "="*60
  end

  desc "Verify all files are accessible on R2"
  task verify_r2: :environment do
    puts "Verifying ActiveStorage files on Cloudflare R2..."

    blobs = ActiveStorage::Blob.where(service_name: 'cloudflare_r2')
    total = blobs.count
    accessible = 0
    errors = []

    puts "Checking #{total} blobs..."

    blobs.find_each.with_index do |blob, index|
      begin
        # Try to access the URL
        url = blob.url
        accessible += 1
        puts "[#{index + 1}/#{total}] ✓ #{blob.filename}"

      rescue => e
        error_msg = "Cannot access #{blob.filename}: #{e.message}"
        errors << error_msg
        puts "[#{index + 1}/#{total}] ✗ #{error_msg}"
      end
    end

    puts "\n" + "="*60
    puts "Verification complete!"
    puts "Accessible: #{accessible}/#{total}"
    puts "Errors: #{errors.count}"

    if errors.any?
      puts "\nErrors:"
      errors.each { |e| puts "  - #{e}" }
    end
    puts "="*60
  end

  desc "Calculate total storage size on R2"
  task calculate_r2_size: :environment do
    blobs = ActiveStorage::Blob.where(service_name: 'cloudflare_r2')
    total_bytes = blobs.sum(:byte_size)
    total_gb = (total_bytes / 1024.0 / 1024.0 / 1024.0).round(2)

    puts "Cloudflare R2 Storage Usage:"
    puts "  Total files: #{blobs.count}"
    puts "  Total size: #{total_gb} GB"
    puts "  Estimated monthly cost: $#{(total_gb * 0.015).round(2)}"
  end
end
```

### Step 12: Test Configuration

Before migrating, test that R2 connection works:

```bash
cd /path/to/robynbase
RAILS_ENV=production bundle exec rails console
```

In the Rails console:
```ruby
# Test R2 connection
service = ActiveStorage::Blob.service_for(:cloudflare_r2)
service.bucket.name
# Should return: "robynbase-assets-production"

# Test upload
blob = ActiveStorage::Blob.create_and_upload!(
  io: StringIO.new("test"),
  filename: "test.txt",
  content_type: "text/plain",
  service_name: 'cloudflare_r2'
)

# Test URL generation
blob.url
# Should return a valid R2 URL

# Clean up test
blob.purge
```

If no errors, you're ready to migrate!

### Step 13: Backup Database

```bash
# Backup database before migration
pg_dump your_database > backup_$(date +%Y%m%d).sql
```

### Step 14: Run Migration

```bash
cd /path/to/robynbase
RAILS_ENV=production bundle exec rake storage:migrate_to_r2
```

**Expected duration:** ~30-60 minutes for 10GB of files

### Step 15: Verify Migration

```bash
RAILS_ENV=production bundle exec rake storage:verify_r2
RAILS_ENV=production bundle exec rake storage:calculate_r2_size
```

---

## Part 4: Testing & Validation (20 minutes)

### Step 16: Test Image Uploads

1. Upload a new image via your app
2. Verify it appears correctly
3. Check the URL - should be:
   - `https://assets.yourdomain.com/...` (if using custom domain)
   - OR `https://pub-xxx.r2.dev/...` (default R2 public URL)

### Step 17: Test Image Display

1. Visit pages with existing images
2. Verify all images load correctly
3. Test image variants/thumbnails
4. Check FancyBox galleries

### Step 18: Test Image Deletion

1. Delete an image from a record
2. Verify it's removed from UI
3. Check R2 bucket - file should be gone

### Step 19: Performance Check

Check load times:
```bash
# Test asset load time
curl -w "@curl-format.txt" -o /dev/null -s "https://assets.yourdomain.com/path/to/image.jpg"
```

Create `curl-format.txt`:
```
time_namelookup:  %{time_namelookup}\n
time_connect:  %{time_connect}\n
time_starttransfer:  %{time_starttransfer}\n
time_total:  %{time_total}\n
```

---

## Part 5: Cleanup (10 minutes)

### Step 20: Remove Old Local Files

**ONLY after confirming everything works:**

```bash
cd /path/to/robynbase

# Archive old files
tar -czf active-storage-backup-$(date +%Y%m%d).tar.gz active-storage-files/

# Move to safe location
mv active-storage-backup-*.tar.gz ~/backups/

# Remove old files (CAUTION!)
rm -rf active-storage-files/*
```

### Step 21: Update Deployment Scripts

If using Capistrano, you can remove the `active-storage-files` shared directory from `config/deploy.rb`:

```ruby
# config/deploy.rb
# Remove this line if present:
# append :linked_dirs, "active-storage-files"
```

---

## Cost Monitoring

### Step 22: Set Up Billing Alerts

1. Go to Cloudflare Dashboard → **Billing** → **Notifications**
2. Create alert for R2 usage:
   - Trigger: R2 storage exceeds X GB
   - Notification: Email

### Expected Monthly Costs:

**For 100GB storage + 1TB bandwidth:**
- Storage: 100GB × $0.015 = $1.50
- Egress: $0.00 (zero egress fees)
- Class A operations (writes): ~$0.01
- Class B operations (reads): ~$0.01
- **Total: ~$1.52/month**

**R2 Free Tier (ongoing):**
- First 10GB storage: FREE
- First 1 million Class A operations/month: FREE
- First 10 million Class B operations/month: FREE
- Zero egress fees forever

### Check Usage:

1. Cloudflare Dashboard → **R2** → **Usage**
2. View storage, operations, and bandwidth metrics

---

## Rollback Plan

If issues occur:

### Quick Rollback:

1. Edit `config/environments/production.rb`:
   ```ruby
   config.active_storage.service = :robyn  # Back to disk
   ```

2. Restart app:
   ```bash
   sudo systemctl restart your-rails-app
   ```

3. Restore files if needed:
   ```bash
   tar -xzf ~/backups/active-storage-backup-YYYYMMDD.tar.gz
   ```

---

## Troubleshooting

### Error: "The authorization header is malformed"

- Check that `force_path_style: true` is set in `storage.yml`
- Verify endpoint URL is correct (should end with `.r2.cloudflarestorage.com`)

### Images not loading:

1. Check bucket public access is enabled (if using public URLs)
2. Verify custom domain DNS is configured correctly
3. Check CORS policy if uploading from browser

### Upload fails with 403:

1. Verify API token has write permissions
2. Check token is scoped to the correct bucket
3. Ensure environment variables are loaded correctly

### Slow uploads:

- R2 automatically selects optimal regions, no tuning needed
- If consistently slow, check your server's network connection

---

## Advanced: Cache Configuration

### Step 23: Configure Cache Control Headers

Add to your initializer (`config/initializers/active_storage.rb`):

```ruby
Rails.application.config.active_storage.content_types_to_serve_as_binary.delete("image/jpeg")
Rails.application.config.active_storage.content_types_to_serve_as_binary.delete("image/png")
Rails.application.config.active_storage.content_types_to_serve_as_binary.delete("image/gif")

# Set cache headers for images
Rails.application.config.after_initialize do
  ActiveStorage::Blob.class_eval do
    def custom_metadata_for_upload
      {
        cache_control: "public, max-age=31536000, immutable"
      }
    end
  end
end
```

This tells browsers to cache images for 1 year.

---

## Performance Optimization

### Cloudflare's Global Network

R2 automatically distributes your assets globally via Cloudflare's network:
- 300+ cities worldwide
- Automatic caching at edge locations
- No configuration needed

### Image Transformation (Optional)

Consider using Cloudflare Images for on-the-fly resizing:
- Pricing: $5/month for 100,000 images
- Automatic WebP conversion
- Responsive image variants

---

## Support Resources

- Cloudflare R2 Docs: https://developers.cloudflare.com/r2/
- R2 Pricing: https://developers.cloudflare.com/r2/pricing/
- Rails ActiveStorage: https://guides.rubyonrails.org/active_storage_overview.html
- S3 API Compatibility: https://developers.cloudflare.com/r2/api/s3/api/

---

## Why Choose R2?

**Pros:**
- Zero egress fees (huge savings as you scale)
- S3-compatible API (easy migration)
- Global distribution via Cloudflare network
- Simple, predictable pricing
- Generous free tier

**Cons:**
- Requires Cloudflare account
- Must enable billing (even for free tier)
- Slightly higher storage cost than Backblaze B2

**Best for:** Projects that expect high bandwidth usage and want predictable costs without egress surprises.

---

**Estimated Total Time:** 1-2 hours
**Difficulty:** Easy
**Cost:** ~$1.50/month for 100GB + unlimited bandwidth
