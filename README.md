

Ever been tempted to use JSON files as application data because it's simple? I was, and this small library is the result.

API

db = (require 'json-crud') 'mydb'

db.put 'collection1', {'property': 'value'}

db.all 'collection1', (err, recs)->
  db.drop 'collection1'

Of course, it's useful to do this over http.

app = (require 'express')()
db.restify app

Now we can do the above as:

POST http://localhost/data/collection1
property value

GET http://localhost/data/collection1

Similar Stuff.

https://github.com/flosse/json-file-store
https://github.com/Softmotions/ejdb

