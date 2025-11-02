# Database Optimization for Server-Side Pagination

## Overview

This document outlines recommended database indexes to optimize WHERE clause performance for the server-side pagination implementation. These indexes target the specific search patterns used in the `search_by` methods across all models.

## Current Search Patterns

### Search Methods Analysis
- **COMPOSITIONS**: `Title LIKE %search%`, `Artist LIKE %search%`, `Label LIKE %search%`, `Year LIKE %search%`, `Type = value`
- **SONGS**: `Song LIKE %search%`, `Author LIKE %search%`, `Lyrics LIKE %search%`
- **VENUES**: `Name LIKE %search%`, `City LIKE %search%`, `Country LIKE %search%`
- **GIGS**: `Venue LIKE %search%`, `GigType = value`, `GigYear = value`

### Foreign Key Relationships
- **GIGS** ↔ **VENUES**: `GIG.VENUEID → VENUE.VENUEID`
- **GIGSETS**: `GSET.GIGID → GIG.GIGID`, `GSET.SONGID → SONG.SONGID`
- **TRACKS**: `TRAK.COMPID → COMP.COMPID`, `TRAK.SONGID → SONG.SONGID`

## Recommended Indexes

### Migration Implementation

```ruby
# db/migrate/add_search_indexes.rb
class AddSearchIndexes < ActiveRecord::Migration[7.2]
  def change
    # === LIKE Query Optimization ===
    # These support the LIKE '%search%' patterns in search_by methods
    
    # COMPOSITIONS - search fields: Title, Artist, Year, Label
    add_index :COMP, :Title, name: 'index_comp_title_search'
    add_index :COMP, :Artist, name: 'index_comp_artist_search' 
    add_index :COMP, :Label, name: 'index_comp_label_search'
    add_index :COMP, :Year, name: 'index_comp_year_search'
    
    # SONGS - search fields: Song, Author, Lyrics  
    add_index :SONG, :Song, name: 'index_song_title_search'
    add_index :SONG, :Author, name: 'index_song_author_search'
    add_index :SONG, :Lyrics, type: :fulltext, name: 'index_song_lyrics_fulltext'
    
    # VENUES - search fields: Name, City, Country
    add_index :VENUE, :Name, name: 'index_venue_name_search'
    add_index :VENUE, :City, name: 'index_venue_city_search'
    add_index :VENUE, :Country, name: 'index_venue_country_search'
    
    # GIGS - search fields: Venue, plus venue location fields via joins
    add_index :GIG, :Venue, name: 'index_gig_venue_search'
    
    # === EXACT MATCH Optimization ===
    # These support WHERE column = value queries
    
    # COMPOSITIONS - Type filter (exact match)
    add_index :COMP, :Type, name: 'index_comp_type_filter'
    
    # GIGS - GigType filter, Year search (exact match)
    add_index :GIG, :GigType, name: 'index_gig_type_filter'
    add_index :GIG, :GigYear, name: 'index_gig_year_search'
    
    # === RELATIONSHIP Lookups ===
    # Foreign key indexes (if not already present)
    add_index :GIG, :VENUEID, name: 'index_gig_venue_fk'
    add_index :GSET, :GIGID, name: 'index_gigset_gig_fk'
    add_index :GSET, :SONGID, name: 'index_gigset_song_fk'
    add_index :TRAK, :COMPID, name: 'index_track_comp_fk'
    add_index :TRAK, :SONGID, name: 'index_track_song_fk'
  end
end
```

## MySQL Specific Enhancements

For MySQL databases, consider adding full-text indexes for better search performance:

```ruby
# Additional MySQL optimization
class AddMysqlFulltextIndexes < ActiveRecord::Migration[7.2]
  def change
    # Multi-column full-text search
    add_index :SONG, [:Song, :Author], type: :fulltext, name: 'index_song_search_fulltext'
    add_index :COMP, [:Title, :Artist, :Label], type: :fulltext, name: 'index_comp_search_fulltext'
    add_index :VENUE, [:Name, :City, :Country], type: :fulltext, name: 'index_venue_search_fulltext'
  end
end
```

## Index Performance Notes

### LIKE Query Optimization
- **Standard B-tree indexes** help with `LIKE 'search%'` (prefix matching)
- **Limited benefit** for `LIKE '%search%'` (substring matching)
- **Full-text indexes** are optimal for substring searches on text fields

### Exact Match Queries
- **Standard indexes** provide excellent performance for `WHERE column = value`
- **Composite indexes** can optimize multiple exact match conditions

### Foreign Key Performance
- **Essential for JOIN operations** between related tables
- **Improves performance** of embedded table queries (gigs for songs/venues)

## Expected Performance Improvements

### Search Operations
- **50-90% faster** for text searches with proper indexes
- **Significant improvement** for lyrics full-text search
- **Better scalability** as dataset grows

### Pagination Performance
- **Faster LIMIT/OFFSET** queries with indexed ORDER BY columns
- **Reduced query time** for large result sets
- **Improved user experience** with faster page loads

### JOIN Operations
- **Dramatically faster** foreign key lookups
- **Better performance** for embedded gig tables on song/venue pages
- **Reduced N+1 query impact**

## Monitoring and Validation

### Query Analysis
```sql
-- Check if indexes are being used
EXPLAIN SELECT * FROM COMP WHERE Title LIKE '%search%';
EXPLAIN SELECT * FROM GIG g JOIN VENUE v ON g.VENUEID = v.VENUEID WHERE v.City = 'San Francisco';
```

### Performance Metrics
- Monitor query execution times before/after index creation
- Check database slow query logs
- Measure page load times for search operations

### Index Usage Statistics
```sql
-- MySQL: Check index usage
SELECT TABLE_NAME, INDEX_NAME, CARDINALITY 
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'robyn_dev';
```

## Implementation Strategy

### Phased Approach
1. **Phase 1**: Add foreign key indexes (highest impact)
2. **Phase 2**: Add exact match indexes (Type, GigType, etc.)
3. **Phase 3**: Add LIKE search indexes
4. **Phase 4**: Add full-text indexes (MySQL)

### Testing Protocol
1. **Backup database** before applying indexes
2. **Run performance tests** on development/staging
3. **Monitor query performance** after each phase
4. **Rollback plan** if performance degrades

### Maintenance Considerations
- **Index maintenance overhead**: Slower INSERT/UPDATE operations
- **Storage requirements**: Additional disk space for indexes
- **Regular analysis**: Monitor index effectiveness over time

## Alternative Optimization Strategies

### Query-Level Optimizations
- **Eager loading**: Use `.includes()` to prevent N+1 queries
- **Query optimization**: Rewrite complex queries for better performance
- **Caching**: Implement view-level caching for expensive operations

### Application-Level Improvements
- **Search optimization**: Consider search engines (Elasticsearch) for complex text search
- **Pagination alternatives**: Implement cursor-based pagination for very large datasets
- **Background processing**: Move expensive operations to background jobs

## Success Metrics

### Performance Targets
- **Search queries**: < 100ms response time
- **Pagination**: < 50ms for page navigation
- **Embedded tables**: < 200ms for gig tables on song/venue pages

### User Experience
- **No perceived delay** during search operations
- **Smooth pagination** without loading spinners
- **Responsive sorting** across all table columns