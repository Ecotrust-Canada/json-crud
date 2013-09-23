Ever been tempted to use JSON files as application data because it's simple? I was, and this small library is the result.

#Examples (in coffeescript)

```coffeescript
db = (require 'json-crud') 'mydb'

db.put 'collection1', {'property': 'value'}

db.all 'collection1', (err, recs)->
  console.log recs
```

Of course, it's useful to do this over http.

```coffeesript
app = (require 'express')()

db.restify app
```

Now we can do the above operations as:

```bash
curl --data "property=value" http://localhost/data/collection1

curl http://localhost/data/collection1
```

#Similar Stuff#

https://github.com/flosse/json-file-store

https://github.com/Softmotions/ejdb

