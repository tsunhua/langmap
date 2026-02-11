# Heatmap API Design Document

## Overview

This document describes the design of a new heatmap API endpoint that will provide aggregated data for rendering the language heatmap on the home page. This endpoint will replace the current approach of fetching all expressions and calculating the heatmap data on the frontend, which is inefficient and causes unnecessary data transfer.

## Background

Currently, the home page heatmap is rendered by:
1. Fetching up to 1000 expressions from the [/api/v1/expressions](file:///Users/lim/Documents/Code/tsunhua/langmap/backend/src/server/api/v1.ts#L36-L53) endpoint
2. Calculating language counts and positions in the browser
3. Rendering the heatmap based on this processed data

This approach has several drawbacks:
1. Performance issues - transferring large amounts of data that is not directly used
2. Resource waste - both server and client spend time processing data that could be pre-calculated
3. Scalability concerns - as the number of expressions grows, this approach becomes increasingly inefficient

## API Endpoint

### Get Heatmap Data

- **URL**: `/api/v1/heatmap`
- **Method**: `GET`
- **Authentication**: Not required

### Response Format

```json
{
  "data": [
    {
      "language_code": "en-US",
      "language_name": "English (United States)",
      "region_code": "US",
      "region_name": "New York",
      "count": 42,
      "latitude": 40.7128,
      "longitude": -74.0060
    },
    {
      "language_code": "zh-CN",
      "language_name": "Chinese (Simplified)",
      "region_code": "CN",
      "region_name": "Beijing",
      "count": 38,
      "latitude": 39.9042,
      "longitude": 116.4074
    }
  ]
}
```

### Response Fields

| Field Name | Type | Description |
|------------|------|-------------|
| language_code | string | ISO language code |
| language_name | string | Human-readable language name |
| region_code | string (optional) | Region code |
| region_name | string (optional) | Region name |
| count | integer | Number of expressions for this language/region |
| latitude | float | Latitude coordinate for the region |
| longitude | float | Longitude coordinate for the region |

### SQL Query Logic

The heatmap data will be generated using an efficient SQL query that performs aggregation in the database. As suggested, we will use the languages table as the primary source and join with expressions to get counts:

```sql
SELECT 
  l.code as language_code,
  l.name as language_name,
  l.region_name,
  l.region_code,
  COALESCE(e.expression_count, 0) as count,
  l.region_latitude as latitude,
  l.region_longitude as longitude
FROM languages l
LEFT JOIN (
  SELECT 
    language_code, 
    COUNT(*) as expression_count
  FROM expressions 
  WHERE region_name IS NOT NULL
  GROUP BY language_code
) e ON l.code = e.language_code
WHERE l.is_active = 1 
  AND l.region_name IS NOT NULL 
  AND l.region_latitude IS NOT NULL 
  AND l.region_longitude IS NOT NULL
ORDER BY count DESC
LIMIT 1000
```

This approach is much more efficient because:
1. We're using the languages table as our primary data source, which is smaller than the expressions table
2. We're only counting expressions when needed through a subquery
3. We're using LEFT JOIN to ensure all active languages with region info are included, even if they have zero expressions
4. We're filtering at the database level to only return relevant data

## Caching Strategy

To improve performance and reduce database load, the heatmap data will be cached in memory for 10 minutes (600 seconds).

### Cache Implementation

1. **Cache Storage**: Use in-memory storage to hold the heatmap data and a timestamp
2. **Cache Duration**: 10 minutes (600 seconds) 
3. **Cache Key**: Single key for the entire heatmap dataset
4. **Cache Invalidation**: Simple approach - only expire cache based on time, no immediate invalidation needed

### Cache Flow

```
Client Request -> Check Cache -> Cache Hit? -> Return Cached Data
                    |
               Cache Miss/Expired
                    |
               Query Database
                    |
               Update Cache
                    |
               Return Fresh Data
```

### Benefits of Caching

1. **Reduced Database Load**: Fewer queries to the database for the same data
2. **Faster Response Times**: Eliminates query execution time for cache hits
3. **Improved User Experience**: Consistent response times regardless of database load
4. **Scalability**: Better handling of traffic spikes

## Implementation Details

### Backend Implementation

1. Add a new `getHeatmapData()` method to the database abstraction layer
2. Implement the method in the D1 database service with the SQL query above
3. Add caching mechanism to store and retrieve heatmap data
4. Add a new `/heatmap` route in the API v1 routes

### Frontend Implementation

1. Modify the Home.vue component to fetch heatmap data from the new [/api/v1/heatmap](file:///Users/lim/Documents/Code/tsunhua/langmap/backend/src/server/api/v1.ts#L18-L18) endpoint
2. Simplify the data processing logic since the backend will provide pre-aggregated data
3. Maintain the same visualization logic for rendering the heatmap

## Performance Benefits

1. **Reduced Data Transfer**: Instead of transferring raw expression data, only transfer aggregated data needed for visualization
2. **Server-Side Processing**: Move computation from client to server where it can be optimized
3. **Improved User Experience**: Faster loading times and reduced browser processing
4. **Better Scalability**: Efficient querying allows handling larger datasets
5. **Efficient Querying**: Using languages table as primary source reduces query complexity
6. **Caching**: Further reduces response times and database load

## Test Cases

### Successful Response

```
GET /api/v1/heatmap

Response:
Status: 200 OK
Content-Type: application/json

{
  "data": [
    {
      "language_code": "en-US",
      "language_name": "English (United States)",
      "region_code": "US",
      "region_name": "New York",
      "count": 42,
      "latitude": 40.7128,
      "longitude": -74.0060
    }
  ]
}
```

### Error Handling

If there's a database error, the API should return a 500 error:
```
Status: 500 Internal Server Error
Content-Type: application/json

{
  "error": "Failed to fetch heatmap data"
}
```

## Future Enhancements

1. Add filtering options (by date range, language, region)
2. Provide different aggregation levels (country-level, city-level)
3. Support pagination for large datasets
4. Add historical data for trend analysis