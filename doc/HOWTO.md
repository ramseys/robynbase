# HOWTO

## How to Restore the Robynbase DB locally

This command restores the dev database using the given SQL dump.

The dev database is dropped and recreated, so make sure the dump also recreates the schema.

```
./utilities/restore_dev_from_dump.sh <MYSQL dump file>
```

Note: if this is production dump, you need to remove the CREATE DATABASE statement at the beginning

## Create backup of local db

This command writes a backup of the dev database (robyn_dev) to a backup database (robyn_dev_backup), which it creates from scratch.

```
./utilities/create_backup.sh 
```

## Import a venue location CSV file

Imports location information from a CSV file:

1. Subcity
2. Street Address (1 and 2)
3. Latitude
4. Longitude 

It'll ignore rows that don't have a longitude/latitude.

The command below must be run from the `imports` directory.

```
RAILS_ENV=development ruby import_venue_locations.rb <CSV FILE> [--csv <CSV DUMP DIRECTORY>] [-p]
```

## Diagnose a Passenger error after a deploy

A Passenger error page right after a deploy usually means the app failed to boot. The server addresses are in `config/deploy/staging.rb` and `config/deploy/production.rb`.

### 1. Reproduce the boot outside Passenger

This is the fastest way to get the full stack trace:

```
cd /var/www/robynbase/current
RAILS_ENV=production bundle exec rails runner 'Rails.application.eager_load!; puts :ok'
```

If it fails, the trace shows the cause. If it prints `ok`, the app boots and the problem is in how Passenger starts it (see step 3).

### 2. Find the error in the log

`config/environments/production.rb` logs to standard output, so Rails errors go to Passenger's or the web server's log, not `log/production.log`. In production the error page only shows an Error ID, so search the log for that ID.

```
# find where Passenger logs (if this isn't set, it logs to the web server's error log)
grep -ri -e passenger_log_file -e PassengerLogFile /etc/nginx /etc/apache2 2>/dev/null

sudo tail -200 /var/log/nginx/error.log      # or /var/log/apache2/error.log
sudo grep -A40 '<ERROR_ID>' /var/log/nginx/error.log
```

### 3. Common causes

- **Wrong Ruby.** Capistrano uses the rvm Ruby set in `config/deploy.rb` (`rvm1_ruby_version`), but Passenger uses whatever `passenger_ruby` (nginx) or `PassengerRuby` (Apache) points to. Compare `grep -ri passenger_ruby /etc/nginx /etc/apache2` with `rvm <version> do which ruby`.
- **Bundler version.** Check that the version under `BUNDLED WITH` in `Gemfile.lock` is installed for that Ruby (`gem list bundler`).
- **Gem incompatibility that only shows up in production.** Production boots with precompiled assets, so code that reads the Sprockets manifest runs only there. For example, json 3.x dropped the `create_additions:` option that sprockets < 4.3 passes, which crashed staging at boot but not locally.
- **File name case.** Production eager-loads on a case-sensitive file system, so a file name that doesn't match what Zeitwerk expects fails there even though `bin/rails zeitwerk:check` passes on macOS.
- **Credentials.** Check that `shared/config/master.key` on the server matches the repo's `config/credentials.yml.enc`.
- **Old Passenger.** Check `passenger -v`; old Passenger releases may not support the current Ruby or Rails.
