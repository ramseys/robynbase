# Coding Style Directives

* Follow the eslint rules defined in this repository (if present)
* Avoid multiple return statements in a single method where possible
* Where possible, looks for ways to consolidate solutions that apply to all the difference (and very similar) category pages in this app: Gig, Song, Release, Venue

# Database Migration Guidelines

* When creating migrations that modify the GIG table, always use uppercase "GIG" in the migration file
* After running migrations, check db/schema.rb - the table name may be lowercased to "gig" due to MySQL's lower_case_table_names setting
* If this happens, manually change `create_table "gig"` back to `create_table "GIG"` in schema.rb to maintain consistency with the codebase
* The user will handle fixing schema.rb manually