# CDN Migration Guide - Robyn Hitchcock Database

This directory contains everything you need to migrate your assets from local disk storage to a CDN.

---

## Quick Start

### 1. Run the Cost Calculator

```bash
ruby cdn_cost_calculator.rb
```

This interactive tool will help you estimate costs for different CDN providers based on your specific usage.

**Example input:**
```
Total asset storage size (GB): 100
Monthly bandwidth/transfer (GB): 1000
Estimated API requests per month (thousands): 50
```

The calculator will show you costs for all providers, ranked by price, plus growth projections.

---

## 2. Choose Your Migration Path

Based on your needs, pick the appropriate guide:

### Option A: Backblaze B2 + Cloudflare CDN
**Best for:** Maximum cost savings with high bandwidth

- **Cost:** ~$0.60/month for 100GB + 1TB bandwidth
- **Difficulty:** Medium
- **Time:** 2-3 hours
- **Guide:** [MIGRATION_GUIDE_BACKBLAZE_B2.md](MIGRATION_GUIDE_BACKBLAZE_B2.md)

**Why choose this:**
- FREE bandwidth via Cloudflare Bandwidth Alliance
- Cheapest option for high-traffic sites
- Global CDN performance

---

### Option B: Cloudflare R2
**Best for:** Simple pricing, zero surprises

- **Cost:** ~$1.50/month for 100GB + unlimited bandwidth
- **Difficulty:** Easy
- **Time:** 1-2 hours
- **Guide:** [MIGRATION_GUIDE_CLOUDFLARE_R2.md](MIGRATION_GUIDE_CLOUDFLARE_R2.md)

**Why choose this:**
- Zero egress fees (no bandwidth charges EVER)
- S3-compatible, easy setup
- Global distribution included

---

### Option C: Linode Object Storage
**Best for:** Staying in your ecosystem, predictable costs

- **Cost:** $5/month flat (250GB + 1TB included)
- **Difficulty:** Very Easy
- **Time:** 1 hour
- **Guide:** [MIGRATION_GUIDE_LINODE.md](MIGRATION_GUIDE_LINODE.md)

**Why choose this:**
- Already using Linode infrastructure
- Simple flat pricing
- Easiest migration
- Same region = low latency

---

## Quick Comparison Table

| Provider | Monthly Cost* | Bandwidth Cost | Setup Time | Difficulty |
|----------|--------------|----------------|------------|------------|
| **Backblaze B2 + Cloudflare** | ~$0.60 | FREE | 2-3 hrs | Medium |
| **Cloudflare R2** | ~$1.50 | $0 egress | 1-2 hrs | Easy |
| **Linode Object Storage** | $5.00 flat | Included 1TB | 1 hr | Very Easy |
| **DigitalOcean Spaces** | $5.00 flat | Included 1TB | 1.5 hrs | Easy |
| **Bunny CDN** | ~$10-30 | $0.01/GB | 2 hrs | Medium |
| **AWS S3 + CloudFront** | ~$85+ | $85/TB | 1.5 hrs | Easy |

*Based on 100GB storage + 1TB bandwidth

---

## Migration Process Overview

All guides follow this same general process:

1. **Setup** (15-30 min)
   - Create account/bucket
   - Generate API keys
   - Configure settings

2. **Rails Configuration** (20-45 min)
   - Update `config/storage.yml`
   - Set environment variables
   - Update production config

3. **Data Migration** (30-120 min)
   - Run migration rake task
   - Verify uploads
   - Test functionality

4. **Testing** (15-30 min)
   - Test uploads
   - Test downloads
   - Verify images display

5. **Cleanup** (10-15 min)
   - Remove old files
   - Update deployment scripts

---

## Files in This Directory

```
cdn_cost_calculator.rb              # Interactive cost calculator
MIGRATION_GUIDE_BACKBLAZE_B2.md     # Detailed B2 + Cloudflare guide
MIGRATION_GUIDE_CLOUDFLARE_R2.md    # Detailed R2 guide
MIGRATION_GUIDE_LINODE.md           # Detailed Linode guide
CDN_MIGRATION_README.md             # This file
```

---

## Current Setup

Your application currently uses:

- **Framework:** Rails 7.2.0
- **Storage:** ActiveStorage with local disk
- **Location:** `/active-storage-files/` (production)
- **Models:** Compositions and Gigs have `has_many_attached :images`
- **Image Processing:** MiniMagick (auto-resize to 1200x1200)

---

## What Gets Migrated

All files stored via ActiveStorage:
- Composition images
- Gig images
- Any other uploaded attachments

**Not migrated** (these stay local):
- Application assets (CSS, JS, icons)
- Static images in `/public/`
- Legacy images in `/public/images/album-art/`

---

## Pre-Migration Checklist

Before starting any migration:

- [ ] Run cost calculator to understand costs
- [ ] Choose a CDN provider
- [ ] Backup your database
- [ ] Have SSH access to your server
- [ ] Test on staging first (if available)
- [ ] Schedule during low-traffic period
- [ ] Notify users of potential downtime (optional)

---

## Post-Migration Checklist

After migration is complete:

- [ ] Verify all images display correctly
- [ ] Test uploading new images
- [ ] Test deleting images
- [ ] Check image URLs in browser dev tools
- [ ] Monitor error logs for 24-48 hours
- [ ] Archive old local files (don't delete immediately)
- [ ] Set up billing alerts
- [ ] Document your configuration

---

## Rollback Plan

All guides include detailed rollback instructions. Quick version:

1. Edit `config/environments/production.rb`:
   ```ruby
   config.active_storage.service = :robyn  # Back to disk
   ```

2. Restart your Rails app

3. Restore files from backup if needed

---

## Getting Help

If you run into issues during migration:

1. Check the **Troubleshooting** section in your specific guide
2. Review Rails logs: `tail -f log/production.log`
3. Check ActiveStorage documentation
4. Consult provider documentation (linked in each guide)

---

## Recommended Choice

Based on your current Linode setup and likely usage:

**For simplicity:** Start with **Linode Object Storage**
- Easiest migration
- Predictable $5/month
- Same infrastructure

**For cost optimization:** Migrate to **Backblaze B2 + Cloudflare**
- Lowest cost at scale
- Free bandwidth
- Worth the extra setup time

**For simplicity + scale:** Use **Cloudflare R2**
- Middle ground on pricing
- Zero egress fees forever
- Easy setup

---

## Questions to Consider

Before choosing, think about:

1. **Current usage:**
   - How much storage do you have now?
   - How much bandwidth per month?
   - Run: `du -sh active-storage-files/`

2. **Growth expectations:**
   - Expect to grow quickly?
   - Bandwidth-heavy usage patterns?

3. **Technical comfort:**
   - Want simplest option?
   - Willing to configure Cloudflare?

4. **Budget:**
   - Prefer flat predictable cost?
   - Want absolute minimum cost?

---

## Next Steps

1. **Run the calculator:**
   ```bash
   ruby cdn_cost_calculator.rb
   ```

2. **Review the results and pick a provider**

3. **Open the appropriate migration guide**

4. **Set aside 1-3 hours** (depending on provider)

5. **Follow the guide step-by-step**

6. **Test thoroughly before removing local files**

---

## Questions?

If anything is unclear in the migration guides, or you need help choosing:

1. Review the cost comparison
2. Check the troubleshooting sections
3. Consider starting with Linode (easiest)
4. Test on staging first if available

---

**Good luck with your migration!**

All three options are solid choices. Pick the one that best matches your priorities:
- **Speed/Ease** → Linode
- **Cost** → Backblaze B2 + Cloudflare
- **Balance** → Cloudflare R2
