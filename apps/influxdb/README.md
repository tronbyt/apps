# InfluxDB App

This app allows you to query an InfluxDB instance and visualize the data as a plot. It supports both InfluxDB v1 (using the query API) and InfluxDB v2 (using the v1 compatibility API).

## Configuration Options

*   **InfluxDB URL**: The full URL of your InfluxDB instance (e.g., `https://us-west-2-1.aws.cloud2.influxdata.com`).
*   **Token / Password**: Your InfluxDB API token (for v2) or user:password (for v1/basic auth).
*   **Database / Bucket**: The name of the database (v1) or the bucket ID mapped to a database (v2).
*   **Query**: The InfluxQL query to execute. This query should return a time series of values. Example: `SELECT value FROM cpu_load LIMIT 20`.
*   **Plot Color**: The color of the line chart for the first query.
*   **Unit**: The unit string to append to the value text (e.g., `%`, `°C`).
*   **Text Color**: The color of the value text for the first query.
*   **Query 2 (Optional)**: A second InfluxQL query to overlay on the same plot.
*   **Plot Color 2**: The color of the line chart for the second query.
*   **Unit 2**: The unit string to append to the value text for the second query.
*   **Text Color 2**: The color of the value text for the second query.
*   **Title**: An optional title to display above the plot. If set, the plot height will be reduced to accommodate the title.
*   **Y Min**: Force a minimum value for the Y-axis. Leave blank for automatic scaling.
*   **Y Max**: Force a maximum value for the Y-axis. Leave blank for automatic scaling.
*   **Show Value Text**: Toggle to show the most recent value(s) as text overlaying the plot.

## Example Query

To get a simple time series:
```sql
SELECT mean("usage_user") FROM "cpu" WHERE time > now() - 1h GROUP BY time(1m)
```
