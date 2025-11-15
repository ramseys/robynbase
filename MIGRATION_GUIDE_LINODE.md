# Migration Guide: Linode Object Storage

**Best for:** Staying in the Linode ecosystem, predictable flat pricing
**Difficulty:** Very Easy
**Estimated Time:** 1 hour
**Monthly Cost:** $5/month flat (250GB storage + 1TB bandwidth)

---

## Overview

This guide walks you through migrating your Rails ActiveStorage assets from local disk storage on your Linode instance to Linode Object Storage - staying within your existing Linode infrastructure with S3-compatible storage.

---

## Prerequisites

- [ ] Existing Linode account (you already have this!)
- [ ] SSH access to your Linode server
- [ ] Database backup (recommended)
- [ ] Rails app with ActiveStorage

---

## Part 1: Linode Object Storage Setup (15 minutes)

### Step 1: Enable Object Storage in Linode

1. Log into Linode Cloud Manager: https://cloud.linode.com
2. Click **Object Storage** in the left sidebar
3. Click **Enable Object Storage** (if not already enabled)
4. Confirm the $5/month flat fee

**Note:** You get 250GB storage + 1TB bandwidth included for $5/month flat rate.

### Step 2: Choose a Region

Select a region close to your Linode instance for best performance:

**Available Regions:**
- `us-east-1` - Newark, NJ (us-east)
- `us-southeast-1` - Atlanta, GA
- `eu-central-1` - Frankfurt, Germany
- `ap-south-1` - Singapore
- `us-lax-1` - Los Angeles, CA

**Recommendation:** Choose the same region as your Linode instance.

### Step 3: Create a Bucket

1. In Object Storage, click **Create Bucket**

**Bucket Configuration:**
```
Label: robynbase-assets-production
Region: us-east-1 (or your chosen region)
Enable CORS: No (we'll configure this later if needed)
```

2. Click **Create Bucket**

3. Note your bucket details:
   - Bucket name: `robynbase-assets-production`
   - Hostname: `us-east-1.linodeobjects.com` (varies by region)
   - Full endpoint: `https://us-east-1.linodeobjects.com`

### Step 4: Create Access Keys

1. Click **Access Keys** tab
2. Click **Create Access Key**

**Access Key Configuration:**
```
Label: robynbase-rails-app
Limited Access: No (or select your bucket for limited access)
```

3. Click **Create Access Key**

4. **IMPORTANT:** Save these credentials immediately (shown only once):
   - `Access Key` (this is your Access Key ID)
   - `Secret Key` (this is your Secret Access Key)

**Example:**
```
Access Key: LINODE_ACCESS_KEY_ABC123
Secret Key: LINODE_SECRET_KEY_xyz789
```

---

## Part 2: Rails Application Configuration (20 minutes)

### Step 5: Update Gemfile

The `aws-sdk-s3` gem should already be available. Verify in your `Gemfile`:

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

# NEW: Linode Object Storage Production
linode:
  service: S3
  access_key_id: <%= ENV['LINODE_ACCESS_KEY_ID'] %>
  secret_access_key: <%= ENV['LINODE_SECRET_ACCESS_KEY'] %>
  region: us-east-1  # Match your bucket region
  bucket: robynbase-assets-production
  endpoint: https://us-east-1.linodeobjects.com
  public: true
```

**Important Region Endpoints:**
- `us-east-1`: `https://us-east-1.linodeobjects.com`
- `us-southeast-1`: `https://us-southeast-1.linodeobjects.com`
- `eu-central-1`: `https://eu-central-1.linodeobjects.com`
- `ap-south-1`: `https://ap-south-1.linodeobjects.com`
- `us-lax-1`: `https://us-lax-1.linodeobjects.com`

### Step 7: Set Environment Variables

**On your Linode server:**

Add to your environment configuration (e.g., `.env`, systemd service, or Capistrano):

```bash
# Linode Object Storage Credentials
LINODE_ACCESS_KEY_ID=your_access_key_here
LINODE_SECRET_ACCESS_KEY=your_secret_key_here
```

**For systemd service** (e.g., `/etc/systemd/system/your-app.service`):
```ini
[Service]
Environment="LINODE_ACCESS_KEY_ID=your_access_key"
Environment="LINODE_SECRET_ACCESS_KEY=your_secret_key"
```

**For Capistrano deployments**, add to `config/deploy/production.rb`:

```ruby
# config/deploy/production.rb
set :default_env, {
  'LINODE_ACCESS_KEY_ID' => 'your_access_key',
  'LINODE_SECRET_ACCESS_KEY' => 'your_secret_key'
}
```

**Alternatively**, use Rails encrypted credentials:

```bash
EDITOR=nano rails credentials:edit --environment production
```

Add:
```yaml
linode:
  access_key_id: your_access_key_here
  secret_access_key: your_secret_key_here
```

Then update `storage.yml`:
```yaml
linode:
  service: S3
  access_key_id: <%= Rails.application.credentials.dig(:linode, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:linode, :secret_access_key) %>
  region: us-east-1
  bucket: robynbase-assets-production
  endpoint: https://us-east-1.linodeobjects.com
  public: true
```

### Step 8: Update Production Environment

Edit `config/environments/production.rb`:

```ruby
# config/environments/production.rb

# Change from :robyn to :linode
config.active_storage.service = :linode

# Keep existing settings
config.assets.compile = false
config.assets.digest = true
```

### Step 9: Configure CORS (If needed)

If your app uploads files directly from browser JavaScript:

1. In Linode Cloud Manager, go to your bucket
2. Click **Access** tab
3. Under **CORS**, enable it and add:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CORSConfiguration>
  <CORSRule>
    <AllowedOrigin>https://yourdomain.com</AllowedOrigin>
    <AllowedOrigin>https://www.yourdomain.com</AllowedOrigin>
    <AllowedMethod>GET</AllowedMethod>
    <AllowedMethod>PUT</AllowedMethod>
    <AllowedMethod>POST</AllowedMethod>
    <AllowedMethod>DELETE</AllowedMethod>
    <AllowedMethod>HEAD</AllowedMethod>
    <AllowedHeader>*</AllowedHeader>
    <ExposeHeader>ETag</ExposeHeader>
    <MaxAgeSeconds>3600</MaxAgeSeconds>
  </CORSRule>
</CORSConfiguration>
```

---

## Part 3: Data Migration (30-60 minutes)

### Step 10: Create Migration Script

Create `lib/tasks/migrate_to_linode.rake`:

```ruby
# lib/tasks/migrate_to_linode.rake

namespace :storage do
  desc "Migrate existing ActiveStorage files to Linode Object Storage"
  task migrate_to_linode: :environment do
    puts "Starting migration of ActiveStorage files to Linode Object Storage..."
    puts "Region: us-east-1"
    puts "Bucket: robynbase-assets-production"
    puts ""

    attachments = ActiveStorage::Attachment.includes(:blob).all
    total = attachments.count
    migrated = 0
    skipped = 0
    errors = []

    puts "Found #{total} attachments to migrate\n\n"

    attachments.find_each.with_index do |attachment, index|
      begin
        blob = attachment.blob

        # Skip if already on Linode
        if blob.service_name == 'linode'
          puts "[#{index + 1}/#{total}] Skipping #{blob.filename} (already on Linode)"
          skipped += 1
          next
        end

        # Download file from local disk
        file_data = blob.download

        # Upload to Linode Object Storage
        new_blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new(file_data),
          filename: blob.filename,
          content_type: blob.content_type,
          service_name: 'linode'
        )

        # Update attachment to point to new blob
        attachment.update!(blob: new_blob)

        # Delete old blob from disk
        blob.purge

        migrated += 1
        size_mb = (blob.byte_size / 1024.0 / 1024.0).round(2)
        puts "[#{index + 1}/#{total}] ✓ Migrated: #{blob.filename} (#{size_mb} MB)"

      rescue => e
        error_msg = "Failed to migrate #{blob&.filename}: #{e.message}"
        errors << error_msg
        puts "[#{index + 1}/#{total}] ✗ #{error_msg}"
      end
    end

    puts "\n" + "="*70
    puts "Migration complete!"
    puts "Successfully migrated: #{migrated}/#{total}"
    puts "Skipped: #{skipped}"
    puts "Errors: #{errors.count}"

    if errors.any?
      puts "\nErrors encountered:"
      errors.each { |e| puts "  - #{e}" }
    end
    puts "="*70
  end

  desc "Verify all files are accessible on Linode Object Storage"
  task verify_linode: :environment do
    puts "Verifying ActiveStorage files on Linode Object Storage..."

    blobs = ActiveStorage::Blob.where(service_name: 'linode')
    total = blobs.count
    accessible = 0
    errors = []

    puts "Checking #{total} blobs...\n\n"

    blobs.find_each.with_index do |blob, index|
      begin
        # Try to access the URL
        url = blob.url

        # Optionally, make HTTP request to verify it's really accessible
        # uri = URI(url)
        # response = Net::HTTP.get_response(uri)
        # raise "HTTP #{response.code}" unless response.code == "200"

        accessible += 1
        puts "[#{index + 1}/#{total}] ✓ #{blob.filename}"

      rescue => e
        error_msg = "Cannot access #{blob.filename}: #{e.message}"
        errors << error_msg
        puts "[#{index + 1}/#{total}] ✗ #{error_msg}"
      end
    end

    puts "\n" + "="*70
    puts "Verification complete!"
    puts "Accessible: #{accessible}/#{total}"
    puts "Errors: #{errors.count}"

    if errors.any?
      puts "\nErrors:"
      errors.each { |e| puts "  - #{e}" }
    end
    puts "="*70
  end

  desc "Calculate total storage size on Linode Object Storage"
  task calculate_linode_size: :environment do
    blobs = ActiveStorage::Blob.where(service_name: 'linode')
    total_bytes = blobs.sum(:byte_size)
    total_gb = (total_bytes / 1024.0 / 1024.0 / 1024.0).round(2)

    puts "\nLinode Object Storage Usage:"
    puts "  Total files: #{blobs.count}"
    puts "  Total size: #{total_gb} GB"
    puts "  Monthly cost: $5.00 (flat rate, includes 250GB)"

    if total_gb > 250
      overage = total_gb - 250
      overage_cost = overage * 0.02
      puts "  Storage overage: #{overage.round(2)} GB"
      puts "  Overage cost: $#{overage_cost.round(2)}"
      puts "  Total cost: $#{(5 + overage_cost).round(2)}"
    else
      puts "  Well within 250GB included limit!"
    end
  end
end
```

### Step 11: Test Configuration

Before migrating, verify connection works:

```bash
cd /path/to/robynbase
RAILS_ENV=production bundle exec rails console
```

In Rails console:
```ruby
# Test Linode Object Storage connection
service = ActiveStorage::Blob.service_for(:linode)
service.bucket.name
# Should return: "robynbase-assets-production"

# Test upload
blob = ActiveStorage::Blob.create_and_upload!(
  io: StringIO.new("test"),
  filename: "test.txt",
  content_type: "text/plain",
  service_name: 'linode'
)

# Test URL generation
puts blob.url
# Should return a Linode Objects URL

# Clean up test
blob.purge
```

If successful, you're ready to migrate!

### Step 12: Backup Database

```bash
# Create database backup
pg_dump your_database > backup_$(date +%Y%m%d).sql
```

### Step 13: Run Migration

```bash
cd /path/to/robynbase
RAILS_ENV=production bundle exec rake storage:migrate_to_linode
```

**Expected duration:** 30-60 minutes depending on file count and size

### Step 14: Verify Migration

```bash
# Verify all files are accessible
RAILS_ENV=production bundle exec rake storage:verify_linode

# Check storage usage
RAILS_ENV=production bundle exec rake storage:calculate_linode_size
```

---

## Part 4: Testing & Validation (15 minutes)

### Step 15: Test Image Uploads

1. Log into your app
2. Upload a new image (Gig or Composition)
3. Verify it displays correctly
4. Check browser dev tools - URL should be:
   ```
   https://robynbase-assets-production.us-east-1.linodeobjects.com/...
   ```

### Step 16: Test Image Display

1. Visit pages with existing images
2. Verify all images load correctly
3. Test image variants (thumbnails, resized images)
4. Test FancyBox galleries

### Step 17: Test Image Deletion

1. Edit a record and delete an image
2. Verify it's removed from UI
3. Check Linode bucket - file should be deleted

### Step 18: Performance Test

Test latency from your server to Linode Object Storage:

```bash
# From your Linode instance
curl -w "\nTime: %{time_total}s\n" -o /dev/null -s \
  "https://robynbase-assets-production.us-east-1.linodeobjects.com/path/to/file.jpg"
```

Should be very fast since you're in the same region!

---

## Part 5: Cleanup & Optimization (10 minutes)

### Step 19: Remove Old Local Files

**ONLY after confirming everything works for at least 48 hours:**

```bash
cd /path/to/robynbase

# Create archive of old files
tar -czf active-storage-backup-$(date +%Y%m%d).tar.gz active-storage-files/

# Move to backup location
mkdir -p ~/backups
mv active-storage-backup-*.tar.gz ~/backups/

# Verify archive is good
tar -tzf ~/backups/active-storage-backup-*.tar.gz | head

# Remove old files (CAUTION!)
rm -rf active-storage-files/*
```

### Step 20: Update Deployment Configuration

If using Capistrano, you can remove the shared directory for active-storage:

Edit `config/deploy.rb`:
```ruby
# Remove or comment out:
# append :linked_dirs, "active-storage-files"
```

### Step 21: Configure Lifecycle Policies (Optional)

In Linode Cloud Manager:
1. Go to your bucket
2. Click **Lifecycle** tab
3. Configure rules to auto-delete old versions (if versioning enabled)

---

## Cost Monitoring

### Understanding Linode Object Storage Pricing

**Flat Rate: $5/month includes:**
- 250GB storage
- 1TB outbound transfer (bandwidth)

**Overages (after included amounts):**
- Storage: $0.02/GB ($20/TB)
- Bandwidth: $0.005/GB ($5/TB)

### Check Your Usage

1. Go to Linode Cloud Manager
2. Click **Account** → **Billing Info**
3. View Object Storage usage under current charges

### Example Costs:

**Scenario 1: 100GB storage, 500GB bandwidth**
- Cost: $5/month (within free tier)

**Scenario 2: 300GB storage, 1.5TB bandwidth**
- Base: $5
- Storage overage: 50GB × $0.02 = $1.00
- Bandwidth overage: 0.5TB × $5 = $2.50
- Total: $8.50/month

**Scenario 3: 500GB storage, 3TB bandwidth**
- Base: $5
- Storage overage: 250GB × $0.02 = $5.00
- Bandwidth overage: 2TB × $5 = $10.00
- Total: $20/month

### Cost Optimization Tips:

1. **Enable browser caching** - Reduce repeated downloads
2. **Compress images** - Your app already does this via ImageUtils module
3. **Use image variants** - Serve appropriately sized images

---

## Rollback Plan

If issues occur:

### Quick Rollback:

1. Edit `config/environments/production.rb`:
   ```ruby
   config.active_storage.service = :robyn  # Back to disk
   ```

2. Deploy or restart app:
   ```bash
   # If using systemd
   sudo systemctl restart your-rails-app

   # If using Capistrano
   cap production deploy
   ```

3. Restore files from backup if needed:
   ```bash
   cd /path/to/robynbase
   tar -xzf ~/backups/active-storage-backup-YYYYMMDD.tar.gz
   ```

---

## Troubleshooting

### Error: "The AWS Access Key Id you provided does not exist"

**Solution:**
1. Verify environment variables are set correctly
2. Check credentials in Linode Cloud Manager
3. Ensure app has been restarted after setting env vars

### Images not loading:

**Solution:**
1. Check bucket is set to public access (if using public URLs)
2. Verify endpoint URL matches your region
3. Check Rails logs: `tail -f log/production.log`

### Slow uploads:

**Solution:**
1. Ensure your Linode instance is in the same region as bucket
2. Check network connectivity: `ping us-east-1.linodeobjects.com`
3. Consider switching to nearest region

### CORS errors:

**Solution:**
1. Enable CORS in bucket settings
2. Add your domain to allowed origins
3. Restart Rails app after CORS changes

---

## Advanced Configuration

### Custom Domain for Assets (Optional)

You can use your own domain instead of `*.linodeobjects.com`:

1. In Linode Cloud Manager, go to your bucket
2. Click **Access** → **SSL/TLS**
3. Add custom domain (e.g., `assets.yourdomain.com`)
4. Update DNS with provided CNAME record
5. Linode provides free SSL certificate

Then update your storage initializer to use custom domain.

### CDN Integration (Optional)

For global distribution, integrate with a CDN:

**Option 1: Cloudflare (Free)**
1. Add CNAME in Cloudflare DNS pointing to Linode bucket
2. Enable proxy (orange cloud)
3. Configure cache rules

**Option 2: Linode Cloud Manager**
- Linode doesn't offer built-in CDN
- Best option is Cloudflare free tier

### Versioning (Optional)

Enable versioning to keep old versions of files:

1. In bucket settings, enable **Versioning**
2. Configure lifecycle rules to clean up old versions
3. Update Rails app to handle versioned objects if needed

---

## Performance Optimization

### Recommended Settings:

**In your initializer** (`config/initializers/active_storage.rb`):

```ruby
# Set cache headers for better browser caching
Rails.application.config.active_storage.content_types_allowed_inline << 'image/jpeg'
Rails.application.config.active_storage.content_types_allowed_inline << 'image/png'
Rails.application.config.active_storage.content_types_allowed_inline << 'image/gif'

# Remove binary content types for images
Rails.application.config.active_storage.content_types_to_serve_as_binary.delete("image/jpeg")
Rails.application.config.active_storage.content_types_to_serve_as_binary.delete("image/png")
Rails.application.config.active_storage.content_types_to_serve_as_binary.delete("image/gif")
```

### Compression:

Your app already optimizes images via `ImageUtils` module:
- Resizes images over 1200x1200
- Reduces file size before upload

This is perfect - keep using it!

---

## Monitoring

### Set Up Alerts:

1. Linode Cloud Manager → **Account** → **Notifications**
2. Enable billing threshold alerts
3. Set alert for Object Storage overage

### Regular Checks:

Monthly:
- Review Object Storage usage
- Check bandwidth consumption
- Verify costs are as expected

---

## Benefits of Linode Object Storage

**Pros:**
- ✓ Same ecosystem (you're already on Linode)
- ✓ Low latency (same region as your server)
- ✓ Predictable flat pricing ($5/month)
- ✓ S3-compatible (easy integration)
- ✓ Simple setup (15 minutes)
- ✓ No surprise charges (generous included limits)

**Cons:**
- ✗ No built-in CDN (add Cloudflare if needed)
- ✗ Limited regions compared to AWS
- ✗ More expensive than Backblaze B2 at scale

**Best for:** Projects that want simple, predictable pricing and are already using Linode infrastructure.

---

## Support Resources

- Linode Object Storage Docs: https://www.linode.com/docs/products/storage/object-storage/
- Linode API Reference: https://www.linode.com/docs/api/object-storage/
- Rails ActiveStorage Guide: https://guides.rubyonrails.org/active_storage_overview.html
- S3 Compatibility: https://www.linode.com/docs/products/storage/object-storage/guides/s3-compatible-api/

---

## Need Help?

- Linode Support: https://www.linode.com/support/
- Submit a ticket from Cloud Manager
- Community: https://www.linode.com/community/

---

**Estimated Total Time:** 1 hour
**Difficulty:** Very Easy (Easiest option!)
**Cost:** $5/month flat for 250GB + 1TB bandwidth
**Recommendation:** Best choice if you want simplicity and are already on Linode
