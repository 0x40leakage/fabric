<!-- ddoc -->

- CouchDB supports special documents within databases known as “design documents”. These documents, mostly driven by JavaScript you write, are used to build indexes, validate document updates, format query results, and filter replications.
- Map functions accept a single document as the argument and (optionally) `emit()` key/value pairs that are stored in a view.
- `emit()` may be called many times for a single document, so the same document may be available by several different keys.
- Each document is sealed to prevent the situation where one map function changes document state and another receives a modified version.
- For efficiency reasons, documents are passed to a group of map functions - each document is processed by a group of map functions from all views of the related design document. This means that if you trigger an index update for one view in the design document, all others will get updated too.
- Design documents are a special type of CouchDB document that contains application code.
- A design document is a CouchDB document with an id that begins with `_design/`.
- Design documents are just like any other CouchDB document—they replicate along with the other documents in their database and track edit conflicts with the `rev` parameter.
- Design documents are normal JSON documents, denoted by the fact that their `DocID` is prefixed with `_design/`.
- CouchDB looks for views and other application functions in design documents. 
    - The static HTML pages of our application are served as attachments to the design document. Views and validations, however, aren’t stored as attachments; rather, they are directly included in the design document’s JSON body.
![](http://guide.couchdb.org/draft/design/01.png)