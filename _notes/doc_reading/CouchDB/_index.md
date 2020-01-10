<!-- https://docs.couchdb.org/en/stable/api/database/find.html#db-index -->

- Mango is a declarative JSON querying language for CouchDB databases. Mango wraps several index types, starting with the Primary Index out-of-the-box. 
- Mango indexes, with index type `json`, are built using MapReduce Views.
- The `index` object is a JSON array of field names following the sort syntax. Nested fields are also allowed, e.g. “person.name”.
- By default, a JSON index will include all documents that have the indexed fields present, including those which have null values.
- *Partial indexes* allow **documents to be filtered at indexing time**, potentially offering significant performance improvements for query **selectors that don’t map cleanly to a range query on an index**.
	
    ```js
    {
        "selector": {
            "status": {
                "$ne": "archived"
            },
            "type": "user"
        }
    }
    ```

    - Without a partial index, this requires a full index scan to find all the documents of `"type":"user"` that do not have a status of `"archived"`. 
    - To improve response times, we can create an index which excludes documents where `"status": { "$ne": "archived" }` at index time using the `"partial_filter_selector"` field.
    	
        ```js
        // POST /db/_index HTTP/1.1
        // Content-Type: application/json
        // Content-Length: 144
        // Host: localhost:5984

        {
            "index": {
                "partial_filter_selector": {
                    "status": {
                        "$ne": "archived"
                    }
                },
                "fields": ["type"]
            },
            "ddoc" : "type-not-archived",
            "type" : "json"
        }

        {
            "selector": {
                "status": {
                    "$ne": "archived"
                },
                "type": "user"
            },
            "use_index": "type-not-archived"
        }
        ```
    
        - Technically, we don’t need to include the filter on the `"status"` field in the query selector - the partial index ensures this is always true - but including it makes the intent of the selector clearer and will make it easier to take advantage of future improvements to query planning (e.g. automatic selection of partial indexes).