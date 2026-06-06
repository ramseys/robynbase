# Coding Style Directives

* Follow the eslint rules defined in this repository (if present)
* Avoid multiple return statements in a single method where possible
* Where possible, looks for ways to consolidate solutions that apply to all the difference (and very similar) category pages in this app: Gig, Song, Release, Venue
* When editing JS files, do not add or remove semicolons, do not change quote style (single vs double), and do not add arrow-function parentheses. Match the style of lines you are not touching exactly.

# Git

* Before recommending `git checkout`, `git restore`, or any other command that discards uncommitted changes, always run `git diff HEAD -- <file>` in full and confirm there are no functional changes. Never assume a diff is purely cosmetic from a partial view.

# Database Migration Guidelines

* When creating migrations that modify the GIG table, always use uppercase "GIG" in the migration file
* After running migrations, check db/schema.rb - the table name may be lowercased to "gig" due to MySQL's lower_case_table_names setting
* If this happens, change `create_table "gig"` back to `create_table "GIG"` in schema.rb to maintain consistency with the codebase


# npm

* Always pin npm dependencies to exact versions (no `^` or `~` prefixes) in package.json.
* This project uses yarn. Use yarn command to updates its dependencies. In particular: don't use things like `npm install` to install or update dependencies. This project should never have a `package-lock.json` file.

# Plans

Put all plan files in the `./docs/plans` directory.

If there are multiple files involved in the plan (eg, scripts to run as part of it), create a subdirectory under that directory and place them there.
