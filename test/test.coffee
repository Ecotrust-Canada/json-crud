
vows = require 'vows'
assert = require 'assert'
json_crud = require '../index'
fs = require 'fs'


# test data
ID_ATTR = (new Date).valueOf()
db = json_crud 'test_db'

suite = vows.describe('JSON CRUD')

suite.addBatch
  'Drop table':
    topic: ->
      db.drop 'test_table_1', @callback
    "Was dropped":
      topic: ->
        db.all 'test_table_1', @callback
      "Is empty": (recs)->
        assert.lengthOf recs, 0


suite.addBatch
  'Insert':
    topic: ->
      db.put 'test_table_1', {abc: 123, _id: ID_ATTR }, @callback
    'Check inserted record':
      topic: ->
        db.all 'test_table_1', @callback
      'Has 1 record': (recs)->
        assert.lengthOf recs, 1
      'Has correct attribute': (recs)->
        assert.equal recs[0].abc, 123
      'Has correct ID': (recs)->
        assert.equal recs[0]._id, ID_ATTR

suite.addBatch
  'Cleanup':
    topic: ->
      db.drop 'test_table_1', @callback
    'Delete DB': #->
      #assert.equal true, true

      topic: ->
        fs.rmdir "test_db.db", @callback
      'Unlink':
        topic: ->
          fs.exists 'test_db.db', @callback
        'All Gone': (exists)->
          assert.equal exists, false

suite.run()

exports.suite = suite