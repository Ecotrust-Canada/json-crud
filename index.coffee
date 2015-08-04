fs = require 'fs'
exec = require('child_process').exec
_ = require 'underscore'
async = require 'async'
debounce = require './lib/debounce'
path = require 'path'

# A JSON filesystem store allowing read-all and write-one ops.
# It should be concurrency safe WITHIN A SINGLE PROCESS.
module.exports = (db_name, options = {})->
  collections = {}
  dirty_collections = {} # Keep track of which collections need cleaned

  db_name += '.db'
  if options.db_location
    db_name = path.join options.db_location, db_name

  if options.url_path
    url_path = options.url_path + 'data/'
  else
    url_path = '/data/'

  exec 'mkdir -p '+db_name, (err,out,serr)->
    if err then throw err
  
  mark_dirty = (collection)->
    dirty_collections[collection] = 1
    commit()
  
  flush = (done)->
    async.map (Object.keys dirty_collections), (collection, callback)->
        filename = db_name+"/"+collection+".json"
        console.log 'writing', filename
        fs.writeFile filename, JSON.stringify(collections[collection]), (err)->
          throw err if err
          callback()
      , ->
        dirty_collections = {}
        done?()

  # Flush to disk at most once per 100ms
  commit = debounce flush, 200

  api =

    # Drop a collection
    drop: (collection, done)->

      # Ensure collections exists before we can delete it.
      @collection collection, =>
        # Clear memory cache of collection.
        collections[collection] = null
        # Clear collection dirty marker (preventing re-creation)
        if dirty_collections[collection]
          delete dirty_collections[collection]
        # Delete the JSON DB file.
        fs.unlink db_name+"/"+collection+".json", (err)->
          if err then throw err
          done()

    collection: (collection, done)->
      
      filename = db_name+"/"+collection+".json"
      load_collection = ->
        fs.readFile filename, (err, result)->
          if err then throw err
          if not collections[collection] # Check this again to protect against race conditions.
            collections[collection] = JSON.parse result + ''
          done err

      if collections[collection]?
        done null

      else # Check if collection exists - if so, load from disk.

        fs.exists filename, (exists)->
          if exists
            load_collection()
          else
            collections[collection] = []
            mark_dirty collection
            flush -> # Forced flush when a new collection's created.
              done null


    # Passes all records in the collection to a callback @param done()
    all: (collection, done)->
      @collection collection, =>
        done null, collections[collection]


    del: (collection, record, done)->
      if typeof record isnt 'object'
        record =
          _id: record
      @collection collection, =>
        collections[collection] = _.filter collections[collection], (row)->
          row._id isnt record._id
        mark_dirty collection
        done?()


    put: (collection, record, done)->
      # Ensure the collection is loaded before saving an item to it.
      @collection collection, =>

        if record._id
          collections[collection] = _.filter collections[collection], (row)-> row._id isnt record._id

        collections[collection].push record

        mark_dirty collection

        done?()
    
    # Take an express app and expose a collection via a rest interface, defined as follows:
    restify: (app)->
      store = @
      app.get url_path + ":collection/:id/del", (req, res)->
        store.del req.params.collection, {_id: req.params.id}, (err)->
          res.send {success: not err, message: err or ''}

      app.get url_path + ":collection", (req,res)->
        store.all req.params.collection, (err, results)->
          if err then throw err
          res.send results

      counter = 0
      post_json = (req,res)->
        req.params.id ?= (new Date).valueOf() + '' + counter
        counter += 1
        obj = JSON.parse req.body.data
        obj._id ?= req.params.id
        store.put req.params.collection, obj, (err)->
          res.send {success: not err, message: err or ''}

      app.post url_path + ":collection/:id", post_json
      app.post url_path + ":collection", post_json

    collections: (done)->
      exec 'mkdir -p '+db_name, (err,out,serr)->
        if err then throw err
        fs.readdir db_name, (err, files)->
          if err then throw err
          async.map files, (file, callback)->
              file = file.replace ".json", ""
              api.collection file, callback
            , ->
              done collections
