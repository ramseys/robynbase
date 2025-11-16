# Counter Cache Maintenance Guide

This guide explains how to maintain the counter cache columns in your Rails application.

## What Are Counter Caches?

Counter caches store the count of associated records directly in the database, eliminating expensive `COUNT(*)` queries. This application uses counter caches for:

- **`VENUE.gigs_count`** - Number of gigs at each venue
- **`SONG.gigsets_count`** - Number of times each song was performed
- **`COMP.tracks_count`** - Number of tracks on each composition

Rails automatically maintains these counts when records are created, updated, or destroyed.

## Available Rake Tasks

### 1. Verify Counter Accuracy

**Command:**
```bash
rake counter_cache:verify
```

**What it does:**
- Compares cached counts to actual database counts
- Reports any discrepancies found
- Does not modify data (read-only)

**Output when everything is correct:**
```
Verifying counter cache accuracy...

Checking venues... done
Checking songs... done
Checking compositions... done

✅ All counter caches are accurate!
```

**Output when issues are found:**
```
⚠️  Found 3 counter cache discrepancies:
  - Venue 45 (The Borderline): cached=12, actual=15
  - Song 234 (I Often Dream of Trains): cached=87, actual=89
  - Composition 12 (I Often Dream of Trains): cached=10, actual=11

Run 'rake counter_cache:reset_all' to fix these issues.
```

### 2. Reset All Counter Caches

**Command:**
```bash
rake counter_cache:reset_all
```

**What it does:**
- Recalculates and updates all counter caches
- Processes venues, songs, and compositions
- Shows progress for each type
- **This is the main fix-it task**

**Output:**
```
Resetting all counter caches...

✅ Venue gigs_count reset complete (150 venues)
✅ Song gigsets_count reset complete (847 songs)
✅ Composition tracks_count reset complete (123 compositions)

✅ All counter caches reset successfully!
```

### 3. Reset Individual Counter Caches

Reset only specific counter types when you know which one needs fixing.

**Venues only:**
```bash
rake counter_cache:reset_venues
```

**Songs only:**
```bash
rake counter_cache:reset_songs
```

**Compositions only:**
```bash
rake counter_cache:reset_compositions
```

**Output:**
```
Resetting song gigsets_count... 847 songs processed
✅ Song gigsets_count reset complete (847 songs)
```

## When to Use These Tasks

### After Initial Migration

After running the counter cache migration for the first time:

```bash
# Verify the migration backfill worked correctly
rake counter_cache:verify
```

The migration automatically backfills counts, but it's good to verify.

### After Bulk Data Imports

If you import data via SQL, CSV, or any method that bypasses Rails:

```bash
# Import your data first
mysql robynbase_production < import.sql

# Then reset counters
rake counter_cache:reset_all

# Verify everything is correct
rake counter_cache:verify
```

**Why?** Bulk imports bypass Rails callbacks, so counters won't update automatically.

### After Direct Database Modifications

If you use SQL to directly modify records:

```bash
# After running direct SQL updates
rake counter_cache:reset_all
```

**Examples that require counter reset:**
- `DELETE FROM GIG WHERE ...` (instead of `Gig.destroy_all`)
- `UPDATE GIG SET VENUEID = ...` (moving gigs between venues)
- Any raw SQL `INSERT`, `UPDATE`, or `DELETE`

### Periodic Maintenance (Recommended)

Run verification monthly or quarterly as a health check:

```bash
# Add to your monitoring/maintenance scripts
rake counter_cache:verify
```

**Suggested cron job (monthly on the 1st at 2am):**
```cron
0 2 1 * * cd /path/to/robynbase && RAILS_ENV=production bundle exec rake counter_cache:verify
```

If discrepancies are found, you can set up alerts or automatically fix them:
```bash
# More aggressive: auto-fix monthly
0 2 1 * * cd /path/to/robynbase && RAILS_ENV=production bundle exec rake counter_cache:reset_all
```

### Before/After Deployments

**Pre-deployment verification:**
```bash
# Before deploying code changes
RAILS_ENV=production rake counter_cache:verify
```

**Post-deployment verification:**
```bash
# After deploying counter cache changes
RAILS_ENV=production rake counter_cache:verify
```

This ensures deployments don't introduce counter cache issues.

### When Debugging Count Discrepancies

If users report incorrect counts on the UI:

```bash
# First, verify the problem
rake counter_cache:verify

# If issues found, fix them
rake counter_cache:reset_all

# Confirm the fix
rake counter_cache:verify
```

### After Restoring from Backup

After restoring a database backup:

```bash
# Restore your backup first
mysql robynbase_production < backup.sql

# Reset all counters (backup may be stale)
RAILS_ENV=production rake counter_cache:reset_all
```

### When Counters Get Out of Sync

Counter caches can become inaccurate if:

1. **Using `delete_all` instead of `destroy_all`**
   ```ruby
   # ❌ Bypasses callbacks, breaks counter cache
   Gig.where(VENUEID: 1).delete_all

   # ✅ Uses callbacks, maintains counter cache
   Gig.where(VENUEID: 1).destroy_all
   ```

   **Fix:** `rake counter_cache:reset_venues`

2. **Direct SQL modifications**
   ```sql
   -- ❌ Bypasses Rails, breaks counter cache
   DELETE FROM GIG WHERE VENUEID = 1;
   ```

   **Fix:** `rake counter_cache:reset_venues`

3. **Database crashes or interrupted transactions**

   **Fix:** `rake counter_cache:reset_all`

4. **Bugs in counter cache logic (rare)**

   **Fix:** `rake counter_cache:reset_all`

## Recommended Workflows

### Daily Operations Workflow

Normal CRUD operations through Rails don't need manual counter resets:

```ruby
# ✅ These automatically update counters
venue.gigs.create(...)
gig.destroy
song.gigsets.delete(gigset)
```

**No action needed** - Rails handles it automatically!

### Data Migration Workflow

When migrating data:

```bash
# 1. Perform your data migration
rails runner 'DataMigrationScript.run'

# 2. Reset counters (in case migration bypassed Rails)
rake counter_cache:reset_all

# 3. Verify results
rake counter_cache:verify
```

### Emergency Fix Workflow

When users report count issues in production:

```bash
# 1. Check if there's a problem
RAILS_ENV=production rake counter_cache:verify

# 2. If issues found, fix immediately
RAILS_ENV=production rake counter_cache:reset_all

# 3. Confirm the fix
RAILS_ENV=production rake counter_cache:verify

# 4. Investigate why it happened (check logs, recent changes)
```

### Database Maintenance Workflow

Regular database maintenance routine:

```bash
# Weekly or monthly maintenance script
#!/bin/bash

echo "Running database maintenance..."

# Verify counter caches
rake counter_cache:verify

# If issues found, the verify task will tell you
# Optionally auto-fix:
# rake counter_cache:reset_all

# Other maintenance tasks...
# rake db:vacuum
# rake db:analyze
```

## Performance Considerations

### Processing Times

Approximate times for resetting counters (on moderate hardware):

| Task | Records | Estimated Time |
|------|---------|----------------|
| reset_venues | 1,000 venues | ~30 seconds |
| reset_songs | 5,000 songs | ~2 minutes |
| reset_compositions | 500 compositions | ~15 seconds |
| reset_all | All records | ~3 minutes |
| verify | All records | ~1 minute |

**Note:** Times scale linearly with record count. Tasks use batching to avoid memory issues.

### Running on Large Datasets

For very large databases (100,000+ records):

```bash
# Run during low-traffic hours
rake counter_cache:reset_all

# Or reset incrementally
rake counter_cache:reset_venues   # Do this at 2am
rake counter_cache:reset_songs    # Do this at 3am
rake counter_cache:reset_compositions  # Do this at 4am
```

### Memory Usage

Tasks use `find_each` which processes records in batches of 1,000, keeping memory usage low (~50-100MB) regardless of dataset size.

## Monitoring and Alerts

### Setting Up Monitoring

Create a monitoring script to check counter health:

```bash
#!/bin/bash
# check_counters.sh

OUTPUT=$(RAILS_ENV=production bundle exec rake counter_cache:verify 2>&1)

if echo "$OUTPUT" | grep -q "⚠️"; then
    # Send alert (email, Slack, PagerDuty, etc.)
    echo "Counter cache issues detected!"
    echo "$OUTPUT"
    # mail -s "Counter Cache Alert" admin@example.com <<< "$OUTPUT"
    exit 1
else
    echo "Counter caches are healthy"
    exit 0
fi
```

Run this in your monitoring system (Nagios, Datadog, etc.).

### Automatic Recovery

For automatic recovery, create a self-healing script:

```bash
#!/bin/bash
# auto_fix_counters.sh

if ! rake counter_cache:verify | grep -q "✅ All counter caches are accurate"; then
    echo "Issues detected, auto-fixing..."
    rake counter_cache:reset_all

    # Verify fix worked
    rake counter_cache:verify
fi
```

**Caution:** Only enable auto-fix if you understand the implications and have proper logging.

## Troubleshooting

### Problem: Verify task reports discrepancies

**Solution:**
```bash
rake counter_cache:reset_all
```

### Problem: Reset task is slow

**Causes:**
- Large dataset
- Database under heavy load
- Slow disk I/O

**Solutions:**
- Run during off-peak hours
- Reset individual counters instead of all
- Check database performance (indexes, query cache)

### Problem: Counters keep getting out of sync

**Common causes:**
1. Using `delete_all` somewhere in code → Change to `destroy_all`
2. Direct SQL modifications → Use ActiveRecord instead
3. Background jobs bypassing ActiveRecord → Update jobs to use models

**Debug steps:**
```bash
# Find code using delete_all
grep -r "delete_all" app/

# Check for raw SQL in code
grep -r "execute\|connection.query" app/

# Review background jobs
ls app/jobs/
```

### Problem: Reset task fails with errors

**Check for:**
- Database connection issues
- Permissions problems
- Records with nil foreign keys

**View detailed errors:**
```bash
rake counter_cache:reset_all --trace
```

## Best Practices

### ✅ DO

- Use `destroy_all` instead of `delete_all` to maintain counters
- Run `verify` task regularly (weekly/monthly)
- Reset counters after bulk imports
- Reset counters after database restores
- Monitor counter health in production
- Document when you manually reset counters

### ❌ DON'T

- Use `delete_all` (bypasses counter cache updates)
- Modify data directly via SQL without resetting counters
- Ignore discrepancies reported by `verify` task
- Run reset tasks during peak traffic hours (for large datasets)
- Modify counter cache columns directly via SQL

## Reference

### Counter Cache Columns

| Table | Column | Counts |
|-------|--------|--------|
| VENUE | gigs_count | Number of gigs at this venue |
| SONG | gigsets_count | Number of times song was performed |
| COMP | tracks_count | Number of tracks on this album |

### How Rails Maintains Counters

Rails automatically updates counters when:
- Creating a record: `venue.gigs.create(...)` → increments `gigs_count`
- Destroying a record: `gig.destroy` → decrements `gigs_count`
- Changing association: `gig.update(VENUEID: 2)` → decrements old venue, increments new venue

### Manual Counter Reset

In Rails console, you can reset individual counters:

```ruby
# Reset a single venue
Venue.reset_counters(venue_id, :gigs)

# Reset all venues
Venue.find_each { |v| Venue.reset_counters(v.VENUEID, :gigs) }
```

But using the rake tasks is recommended for consistency and progress tracking.

## Support

If you encounter issues with counter caches:

1. Run the verify task to identify the problem
2. Check this guide for relevant troubleshooting steps
3. Review recent code changes or data imports
4. Reset counters using the appropriate rake task
5. If problems persist, check Rails logs and database logs

## Summary

**For routine maintenance:**
```bash
rake counter_cache:verify  # Check monthly
```

**When you import data or modify database directly:**
```bash
rake counter_cache:reset_all  # Fix everything
```

**When you just need to check one type:**
```bash
rake counter_cache:reset_venues  # Or songs, or compositions
```

Counter caches are a powerful performance optimization, and these tasks help ensure they stay accurate over time!
