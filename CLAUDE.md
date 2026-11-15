# Coding Style Directives

* Follow the eslint rules defined in this repository (if present)
* Avoid multiple return statements in a single method where possible
* Where possible, look for ways to consolidate solutions that apply to all the category pages in this app: Gig, Song, Release, Venue. They share many similarities, and to the extente possible we should use common code when modifying them / adding new features.
* When editing JS files, do not add or remove semicolons, do not change quote style (single vs double), and do not add arrow-function parentheses. Match the style of lines you are not touching exactly.

# Git

* Before recommending `git checkout`, `git restore`, or any other command that discards uncommitted changes, always run `git diff HEAD -- <file>` in full and confirm there are no functional changes. Never assume a diff is purely cosmetic from a partial view.
* When adding/updating anything that might be sensitive information to staged files (eg, passwords, secret keys, LLM plans) — or noticing that the user added something like this without your inteventin — take into account whether they should be visible in a public git repo, and warn if they shouldn't be.

# Database Migration Guidelines

* When creating migrations that modify the GIG table, always use uppercase "GIG" in the migration file
  * After running migrations, check db/schema.rb - the table name may be lowercased to "gig" due to MySQL's lower_case_table_names setting
  * If this happens, change `create_table "gig"` back to `create_table "GIG"` in schema.rb to maintain consistency with the codebase

# Production Environment

Development runs on macOS with Puma; production does not. Keep the differences in mind for any change that could depend on the runtime environment, and flag it when one does.

* Production runs on a Linux server under Passenger, not Puma. Puma is only in the Gemfile's development group, so don't rely on Puma-specific config or plugins (e.g. running Solid Queue inside Puma).
* Deploys use Capistrano (`config/deploy.rb`): each release is a fresh directory, and Passenger is restarted with `touch tmp/restart.txt`.
* Linux file names are case-sensitive, unlike macOS's default. File names must match what Zeitwerk expects, and partial/template paths must match their case exactly. Something that works locally can fail in production.
* Assume MySQL table names are case-sensitive in production (see the GIG table note above). Raw SQL must use each table's exact name (e.g. `GIG`, `GSET`, `COMP`, `TRAK`, `SONG`, `VENUE`, `MUSO`, but `gigmedia`); prefer letting Active Record build queries from `table_name`.
* No Active Job queue is configured, so background jobs (e.g. Active Storage analysis, `purge_later`) run in threads inside the Passenger process, which Passenger may shut down when idle. Don't rely on a background job for anything that must happen; do it in the request.
* Passenger can run several app processes, so per-process state (class variables, in-memory caches) isn't shared between requests.
* `production.rb` logs to standard output, which under Passenger goes to Passenger's/the web server's log, not `log/production.log`.


# npm

* Always pin npm dependencies to exact versions (no `^` or `~` prefixes) in package.json.
* This project uses yarn. Use yarn command to updates its dependencies. In particular: don't use things like `npm install` to install or update dependencies. This project should never have a `package-lock.json` file.

# Plans

Whenever you're asked to evaluate something in plan mode, create a local plan file for it. Put all plan files in the `./docs/plans` directory.

If there are multiple files involved in the plan (eg, scripts to run as part of it), create a subdirectory under that directory and place them there.


