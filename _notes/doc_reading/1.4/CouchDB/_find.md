<!-- https://docs.couchdb.org/en/stable/api/database/find.html
https://docs.couchdb.org/en/stable/ddocs/views/collation.html#string-ranges -->
- Find documents using a declarative JSON querying syntax. Queries can use the built-in `_all_docs` index or custom indexes, specified using the `_index` endpoint.

    ```js
    // http://localhost:5984/mychannel_mycc/_find
    {
        "selector": {
            "FROM_ORG": "icbc",
            "GMT_MODIFY":{"$gt": "2019-11-17 12:11:13"}
        },
        "fields": ["_id", "_rev", "FROM_ORG", "GMT_MODIFY"],
        "sort": [{"GMT_MODIFY": "desc"}],
        "limit": 1,
        "bookmark": "g1AAAABweJzLYWBgYMpgSmHgKy5JLCrJTq2MT8lPzkzJBYrLMZRUuOXklzNkJiclMxgaAIGhkQkIGRqYWjKAdHHAdOWAzAFpYgEpBjGEjQwMLXUNDXUNLRUMjawMDa0MjbOyADTLGqM",
        "execution_stats": true
    }
    ```

- While `skip` exists, it is not intended to be used for paging. The reason is that the `bookmark` feature is more efficient.
- For best performance, it is best to combine ‘combination’ or ‘array logical’ operators, such as `$regex`, with an equality operators such as `$eq`, `$gt`, `$gte`, `$lt`, and `$lte` (but not `$ne`). 
- A more complex selector enables you to specify the values for field of nested objects, or subfields.
- *Operators* are identified by the use of a dollar sign (`$`) prefix in the name field. There are 2 core types of operators in the selector syntax:
    - Combination operators
    - Condition operators
- In general, combination operators are applied at the topmost level of selection. They are used to combine conditions, or to create combinations of conditions, into one selector. 
- Every *explicit operator* has the form: `{"$operator": argument}`.
- A selector without an explicit operator is considered to have an *implicit operator*. The exact implicit operator is determined by the structure of the selector expression.
- There are 2 implicit operators:
    - Equality
    - And
- In a selector, any field containing a JSON value, but that has no operators in it, is considered to be an equality condition. The implicit equality test applies also for fields and subfields. Any JSON object that is not the argument to a condition operator is an implicit `$and` operator on each field.
	
    ```js
    {
        "director": "Lars von Trier",
        "year": 2003
    }
    // explicit form
    {
        "$and": [
            {
                "director": {
                    "$eq": "Lars von Trier"
                }
            },
            {
                "year": {
                    "$eq": 2003
                }
            }
        ]
    }
    ```

- All operators, apart from ‘Equality’ and ‘And’, must be stated explicitly.
- Combination operators are used to **combine selectors**. A combination operator takes a single argument. The argument is either another selector, or an array of selectors.

Operator |	Argument |	Purpose
--|--|--|
`$and` |	Array |	Matches if all the selectors in the array match.
`$or` |	Array |	Matches if any of the selectors in the array match. All selectors must use the same index.
`$not` |	Selector |	Matches if the given selector does not match.
`$nor` |	Array |	Matches if none of the selectors in the array match.
`$all` |	Array |	Matches an array value if it contains all the elements of the argument array.
`$elemMatch` |	Selector |	Matches and returns all documents that contain an array field with at least one element that matches all the specified query criteria.
`$allMatch` |	Selector |	Matches and returns all documents that contain an array field with all its elements matching all the specified query criteria.

- Condition operators are specific to a field, and are used to evaluate the value stored in that field.

Operator type |	Operator |	Argument |	Purpose
--|--|--|--
(In)equality	| `$lt` |	Any JSON | 	The field is less than the argument
 &nbsp;	| `$lte` |	Any JSON |	The field is less than or equal to the argument.
 &nbsp;	| `$eq` |	Any JSON |	The field is equal to the argument
 &nbsp;	| `$ne` |	Any JSON |	The field is not equal to the argument.
 &nbsp;	| `$gte` |	Any JSON |	The field is greater than or equal to the argument.
 &nbsp;	| `$gt` |	Any JSON |	The field is greater than the to the argument.
Object	| `$exists` |	Boolean |	Check whether the field exists or not, regardless of its value.
 &nbsp;	| `$type` |	String |	Check the document field’s type. Valid values are "null", "boolean", "number", "string", "array", and "object".
Array	| `$in` |	Array of JSON values |	The document field must exist in the list provided.
 &nbsp;	| `$nin` |	Array of JSON values |	The document field not must exist in the list provided.
 &nbsp;	| `$size` |	Integer |	Special condition to match the length of an array field in a document. Non-array fields cannot match this condition.
Miscellaneous	| `$mod` |	[Divisor, Remainder] |	Divisor and Remainder are both positive or negative integers. Non-integer values result in a 404. Matches documents where `field % Divisor == Remainder` is true, and only when the document field is an integer.
 &nbsp;	| `$regex` |	String |	A regular expression pattern to match against the document field. Only matches when the field is a string value and matches the supplied regular expression. The matching algorithms are based on the Perl Compatible Regular Expression (PCRE) library. For more information about what is implemented, see the see the [Erlang Regular Expression](http://erlang.org/doc/man/re.html)

- Regular expressions do not work with indexes, so they should not be used to filter large data sets. They can, however, be used to restrict a partial index.
- In general, whenever you have an operator that takes an argument, that argument can itself be another operator with arguments of its own. This enables us to build up more complex selector expressions.
- However, only equality operators such as `$eq`, `$gt`, `$gte`, `$lt`, and `$lte` (but not `$ne`) can be used as the basis of a query. You should include at least one of these in a selector.
- The sort field contains a list of field name and direction pairs, expressed as a basic array. The first field name and direction pair is the topmost level of sort. The second pair, if provided, is the next level of sort.
- The field can be any field, using dotted notation if desired for sub-document fields.
- The direction value is `"asc"` for ascending, and `"desc"` for descending. If you omit the direction value, the default `"asc"` is used.
- To use sorting, ensure that:
    - At least one of the sort fields is included in the selector.
    - There is an index already defined, with **all the sort fields in the same order**.
    - Each object in the sort array has a single key.
        - If an object in the sort array does not have a single key, the resulting sort order is implementation specific and might change.
- Find does not support multiple fields with different sort orders, so the directions must be either all ascending or all descending.
- For field names in text search sorts, it is sometimes necessary for a field type to be specified, for example: `{"<fieldname>:string": "asc"}`
    - If possible, an attempt is made to discover the field type based on the selector. In ambiguous cases the field type must be provided explicitly.
- The sorting order is undefined when fields contain different data types. This is an important difference between text and view indexes. Sorting behavior for fields with different data types might change in future versions.
- It is possible to specify exactly which fields are returned for a document when selecting from a database. The 2 advantages are:
    1. Your results are limited to only those parts of the document that are required for your application.
    2. A reduction in the size of the response.
- The fields returned are specified as an array. Only the specified filter fields are included, in the response. 
    - There is no automatic inclusion of the `_id` or other metadata fields when a field list is included.
- Mango queries support pagination via the `bookmark` field. Every `_find` response contains a `bookmark` - a token that CouchDB uses to determine where to resume from when subsequent queries are made. To get the next set of query results, add the `bookmark` that was received in the previous response to your next request. 
    - Remember to keep the selector the same, otherwise you will receive unexpected results. 
    - To paginate backwards, you can use a previous bookmark to return the previous set of results.
- The presence of a bookmark doesn’t guarantee that there are more results. You need to test whether you have reached the end of the result set by comparing the number of results returned with the page size requested - if results returned < limit, there are no more.
- Find can return basic execution statistics for a specific request. Combined with the `_explain` endpoint, this should provide some insight as to whether indexes are being used effectively.

    Field | 	Description
    --|--
    `total_keys_examined` |	Number of index keys examined. Currently always 0.
    `total_docs_examined` |	Number of documents fetched from the database / index, equivalent to using `include_docs=true` in a view. These may then be filtered in-memory to further narrow down the result set based on the selector.
    `total_quorum_docs_examined` |	Number of documents fetched from the database using an out-of-band document fetch. This is only non-zero when read quorum > 1 (replica) is specified in the query parameters.
    `results_returned` |	Number of results returned from the query. Ideally this should not be significantly lower than the total documents / keys examined.
    `execution_time_ms` |	Total execution time in milliseconds as measured by the database.

- `_find` chooses which index to use for responding to a query, unless you specify an index at query time.
    - The query planner looks at the selector section and finds the index with the closest match to operators and fields used in the query. If there are 2 or more json type indexes that match, the index with the smallest number of fields in the index is preferred. If there are still 2 or more candidate indexes, the index with the first alphabetical name is chosen.
    - It’s good practice to specify indexes explicitly in your queries. This prevents existing queries being affected by new indexes that might get added in a production environment.

- `_explain` shows which index is being used by the query. Parameters are the same as `_find`.