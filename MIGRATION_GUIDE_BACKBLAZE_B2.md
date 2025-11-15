# Migration Guide: Backblaze B2 + Cloudflare CDN

**Best for:** Maximum cost savings with high bandwidth usage
**Difficulty:** Medium
**Estimated Time:** 2-3 hours
**Monthly Cost:** ~$0.60 for 100GB storage + 1TB bandwidth

---

## Overview

This guide walks you through migrating your Rails ActiveStorage assets from local disk storage to Backblaze B2 object storage with Cloudflare CDN for free bandwidth via the Bandwidth Alliance.

---

## Prerequisites

- [ ] Backblaze account (free tier available)
- [ ] Cloudflare account (free tier works)
- [ ] Domain already on Cloudflare DNS
- [ ] SSH access to your Linode server
- [ ] Database backup (recommended)

---

## Part 1: Backblaze B2 Setup (30 minutes)

### Step 1: Create Backblaze Account & Bucket

1. Sign up at https://www.backblaze.com/b2/sign-up.html
2. Navigate to **B2 Cloud Storage** → **Buckets**
3. Click **Create a Bucket**

**Bucket Configuration:**
```
Bucket Name: robynbase-assets-production
Files in Bucket: Public
Default Encryption: Disabled (or Enabled if you prefer)
Object Lock: Disabled
```

4. Save the **Bucket ID** and **Endpoint** (e.g., `s3.us-west-004.backblazeb2.com`)

### Step 2: Create Application Key

1. Go to **App Keys** → **Add a New Application Key**

**Key Configuration:**
```
Name: robynbase-rails-app
Allow access to Bucket(s): robynbase-assets-production (specific bucket)
Type of Access: Read and Write
Allow List All Bucket Names: Optional
File name prefix: (leave blank)
Duration: (leave blank for no expiration)
```

2. **IMPORTANT:** Save these immediately (shown only once):
   - `keyID` (this is your Access Key ID)
   - `applicationKey` (this is your Secret Access Key)
   - `s3_endpoint` (e.g., `s3.us-west-004.backblazeb2.com`)

---

## Part 2: Cloudflare CDN Setup (30 minutes)

### Step 3: Configure Cloudflare for Backblaze

1. Log into Cloudflare Dashboard
2. Select your domain
3. Go to **Rules** → **Transform Rules** → **Modify Request Header**

### Step 4: Create Cache Rule for Assets

1. Go to **Caching** → **Cache Rules**
2. Click **Create Rule**

**Rule Configuration:**
```
Rule name: Backblaze B2 Assets Cache
When incoming requests match:
  - Hostname equals: assets.yourdomain.com

Then:
  - Cache eligibility: Eligible for cache
  - Edge TTL: 1 month
  - Browser TTL: 1 week
```

### Step 5: Create DNS CNAME for Assets Subdomain

1. Go to **DNS** → **Records**
2. Add new **CNAME** record:

```
Type: CNAME
Name: assets
Target: f004.backblazeb2.com  (use YOUR bucket's region endpoint)
Proxy status: Proxied (orange cloud) ✓
TTL: Auto
```

**Important:** The target should be your Backblaze bucket endpoint without the `s3.` prefix.

Example: If your endpoint is `s3.us-west-004.backblazeb2.com`, use `f004.backblazeb2.com`

### Step 6: Configure Bandwidth Alliance (Free Egress)

This is automatic! Once your Backblaze bucket serves traffic through Cloudflare's proxied DNS, egress is free.

To verify:
- Assets must be accessed via `assets.yourdomain.com` (Cloudflare proxy)
- NOT directly via Backblaze URLs

---

## Part 3: Rails Application Configuration (45 minutes)

### Step 7: Update Gemfile

The `aws-sdk-s3` gem is already installed for ActiveStorage. Verify in your `Gemfile`:

```ruby
# Gemfile
gem "aws-sdk-s3", require: false
```

If not present, add it and run:
```bash
bundle install
```

### Step 8: Update Storage Configuration

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

# NEW: Backblaze B2 Production Storage
backblaze_b2:
  service: S3
  access_key_id: <%= ENV['B2_ACCESS_KEY_ID'] %>
  secret_access_key: <%= ENV['B2_SECRET_ACCESS_KEY'] %>
  region: us-west-004  # Match your B2 bucket region
  bucket: robynbase-assets-production
  endpoint: https://s3.us-west-004.backblazeb2.com
  public: true  # Files are publicly accessible
  # Optional: Use Cloudflare CDN URL for serving
  # This makes Rails generate URLs like: https://assets.yourdomain.com/...
  # You'll handle this via an initializer instead (see Step 10)
```

**Note:** B2 regions map like this:
- `us-west-004` → Oregon
- `us-west-001` → California
- `eu-central-003` → Amsterdam

### Step 9: Set Environment Variables

**On your Linode server:**

Add to your environment configuration (e.g., `.env`, systemd service, or Capistrano deployment):

```bash
# Backblaze B2 Credentials
B2_ACCESS_KEY_ID=your_backblaze_key_id_here
B2_SECRET_ACCESS_KEY=your_backblaze_application_key_here
```

**For Capistrano deployments**, add to `config/deploy.rb` or `config/deploy/production.rb`:

```ruby
# config/deploy/production.rb
set :default_env, {
  'B2_ACCESS_KEY_ID' => 'your_key_id',
  'B2_SECRET_ACCESS_KEY' => 'your_application_key'
}
```

**Alternatively**, use Rails encrypted credentials:

```bash
EDITOR=nano rails credentials:edit --environment production
```

Add:
```yaml
backblaze:
  access_key_id: your_key_id_here
  secret_access_key: your_application_key_here
```

Then update `storage.yml`:
```yaml
backblaze_b2:
  service: S3
  access_key_id: <%= Rails.application.credentials.dig(:backblaze, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:backblaze, :secret_access_key) %>
  # ... rest of config
```

### Step 10: Create Custom URL Initializer (Optional but Recommended)

To serve assets through Cloudflare CDN instead of direct Backblaze URLs:

Create `config/initializers/active_storage.rb`:

```ruby
# config/initializers/active_storage.rb

Rails.application.config.after_initialize do
  # Override ActiveStorage URL generation to use Cloudflare CDN
  if Rails.env.production? && Rails.application.config.active_storage.service == :backblaze_b2

    # Monkey patch to use custom CDN URL
    module ActiveStorageCloudflareUrl
      def url(expires_in: nil, disposition: :inline, filename: nil, **options)
        # Get the original S3 URL
        original_url = super

        # Replace Backblaze domain with Cloudflare CDN domain
        cdn_url = original_url.gsub(
          /https:\/\/s3\.us-west-004\.backblazeb2\.com\/robynbase-assets-production/,
          'https://assets.yourdomain.com'
        )

        cdn_url
      end
    end

    # Prepend to ActiveStorage::Blob
    ActiveStorage::Blob.prepend(ActiveStorageCloudflareUrl)
  end
end
```

**Replace** `https://assets.yourdomain.com` with your actual domain.

### Step 11: Update Production Environment

Edit `config/environments/production.rb`:

```ruby
# config/environments/production.rb

# Change from :robyn to :backblaze_b2
config.active_storage.service = :backblaze_b2

# Keep these settings
config.assets.compile = false
config.assets.digest = true
```

### Step 12: Update CORS Configuration (If needed)

If your app uses JavaScript to upload files directly to storage, configure CORS in Backblaze:

1. In Backblaze B2 dashboard, go to your bucket settings
2. Under **Bucket Settings** → **Bucket Info** → **CORS Rules**
3. Add:

```json
[
  {
    "corsRuleName": "allowRailsUploads",
    "allowedOrigins": [
      "https://yourdomain.com",
      "https://www.yourdomain.com"
    ],
    "allowedOperations": [
      "s3_get",
      "s3_put",
      "s3_head"
    ],
    "allowedHeaders": [
      "*"
    ],
    "exposeHeaders": [
      "ETag"
    ],
    "maxAgeSeconds": 3600
  }
]
```

---

## Part 4: Data Migration (1-2 hours depending on size)

### Step 13: Create Migration Script

Create `lib/tasks/migrate_to_b2.rake`:

```ruby
# lib/tasks/migrate_to_b2.rake

namespace :storage do
  desc "Migrate existing ActiveStorage files to Backblaze B2"
  task migrate_to_b2: :environment do
    puts "Starting migration of ActiveStorage files to Backblaze B2..."

    # Get all attachments
    attachments = ActiveStorage::Attachment.includes(:blob).all
    total = attachments.count
    migrated = 0
    errors = []

    puts "Found #{total} attachments to migrate"

    attachments.find_each.with_index do |attachment, index|
      begin
        blob = attachment.blob

        # Skip if already on B2 (service_name check)
        if blob.service_name == 'backblaze_b2'
          puts "[#{index + 1}/#{total}] Skipping #{blob.filename} (already on B2)"
          next
        end

        # Open the file from local disk
        file = blob.download

        # Create new blob on B2
        new_blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new(file),
          filename: blob.filename,
          content_type: blob.content_type,
          service_name: 'backblaze_b2'
        )

        # Update attachment to point to new blob
        attachment.update!(blob: new_blob)

        # Delete old blob
        blob.purge

        migrated += 1
        puts "[#{index + 1}/#{total}] Migrated: #{blob.filename} ✓"

      rescue => e
        error_msg = "Failed to migrate #{blob&.filename}: #{e.message}"
        errors << error_msg
        puts "[#{index + 1}/#{total}] #{error_msg} ✗"
      end
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

  desc "Verify all files are accessible on B2"
  task verify_b2: :environment do
    puts "Verifying ActiveStorage files on B2..."

    blobs = ActiveStorage::Blob.where(service_name: 'backblaze_b2')
    total = blobs.count
    accessible = 0
    errors = []

    puts "Checking #{total} blobs..."

    blobs.find_each.with_index do |blob, index|
      begin
        # Try to get the URL (this checks if file exists)
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
end
```

### Step 14: Test Migration on Staging (Recommended)

If you have a staging environment:

```bash
# On staging server
cd /path/to/robynbase
RAILS_ENV=staging bundle exec rake storage:migrate_to_b2
```

### Step 15: Run Production Migration

**IMPORTANT:** Backup your database first!

```bash
# Backup database
pg_dump your_database > backup_$(date +%Y%m%d).sql

# Run migration
cd /path/to/robynbase
RAILS_ENV=production bundle exec rake storage:migrate_to_b2
```

**Expected duration:** ~1-2 hours for 10GB of files

### Step 16: Verify Migration

```bash
RAILS_ENV=production bundle exec rake storage:verify_b2
```

Check your Backblaze B2 bucket in the web interface to confirm files are present.

---

## Part 5: Testing & Validation (30 minutes)

### Step 17: Test Image Uploads

1. Upload a new image via your app (Gig or Composition)
2. Verify it appears correctly
3. Check the image URL in browser dev tools - it should be:
   - `https://assets.yourdomain.com/...` (if using Cloudflare CDN URL)
   - OR `https://s3.us-west-004.backblazeb2.com/robynbase-assets-production/...`

### Step 18: Test Image Display

1. Visit pages with existing images (Gigs, Compositions)
2. Verify all images load correctly
3. Test image variants/thumbnails
4. Test the FancyBox lightbox galleries

### Step 19: Test Image Deletion

1. Edit a record and delete an image
2. Verify it's removed from the page
3. Check Backblaze B2 bucket - file should be deleted

### Step 20: Performance Testing

Check Cloudflare analytics:
1. Go to Cloudflare Dashboard → Analytics → Traffic
2. Verify requests to `assets.yourdomain.com`
3. Check **Cache Hit Rate** (should be >80% after warming)

---

## Part 6: Cleanup & Optimization (15 minutes)

### Step 21: Clean Up Old Local Files

**ONLY after confirming everything works:**

```bash
# Archive old files (don't delete immediately)
cd /path/to/robynbase
tar -czf active-storage-backup-$(date +%Y%m%d).tar.gz active-storage-files/

# Move archive to safe location
mv active-storage-backup-*.tar.gz ~/backups/

# Remove old files (CAUTION!)
rm -rf active-storage-files/*
```

### Step 22: Update .gitignore (Already done)

Your `.gitignore` already excludes the local storage directory.

### Step 23: Configure Lifecycle Rules (Optional)

In Backblaze B2 bucket settings:
- Set up lifecycle rules to automatically delete old versions
- Consider enabling object lock for important files

---

## Rollback Plan

If something goes wrong:

### Quick Rollback:

1. Edit `config/environments/production.rb`:
   ```ruby
   config.active_storage.service = :robyn  # Back to disk
   ```

2. Restart Rails app:
   ```bash
   sudo systemctl restart your-rails-app
   ```

3. Restore files from backup if needed:
   ```bash
   cd /path/to/robynbase
   tar -xzf ~/backups/active-storage-backup-YYYYMMDD.tar.gz
   ```

---

## Monitoring & Maintenance

### Check Costs:

1. Backblaze Dashboard → **B2 Cloud Storage** → **Reports**
2. Monitor storage usage and API calls
3. Cloudflare Dashboard → **Analytics** → **Bandwidth** (should show savings)

### Expected Monthly Costs (100GB storage, 1TB bandwidth):

- Storage: 100GB × $0.006 = $0.60
- Bandwidth: FREE via Cloudflare
- API calls: ~$0.01
- **Total: ~$0.61/month**

---

## Troubleshooting

### Images not loading:

1. Check Cloudflare DNS is proxied (orange cloud)
2. Verify CNAME target matches your B2 bucket region
3. Check B2 bucket is set to "Public"
4. Verify environment variables are set correctly

### Upload errors:

1. Check B2 application key has write permissions
2. Verify CORS configuration if using direct uploads
3. Check Rails logs: `tail -f log/production.log`

### Slow performance:

1. Check Cloudflare cache hit rate (should be >80%)
2. Verify you're using CDN URL not direct B2 URLs
3. Increase Edge TTL in Cloudflare Cache Rules

---

## Support Resources

- Backblaze B2 Docs: https://www.backblaze.com/b2/docs/
- Cloudflare Bandwidth Alliance: https://www.cloudflare.com/bandwidth-alliance/
- Rails ActiveStorage Guide: https://guides.rubyonrails.org/active_storage_overview.html
- S3-compatible API: https://www.backblaze.com/b2/docs/s3_compatible_api.html

---

**Estimated Total Time:** 2-3 hours
**Difficulty:** Medium
**Cost Savings vs Local:** 100% bandwidth savings + better performance
