
# Limit the number of times a function is called. @returns a wrapper with this behaviour.
module.exports = (fn, interval)->
  pending = false
  ->
    args = arguments
    that = this
    if not pending
      pending = true
      setTimeout ->
        pending = false
        fn.apply that, args
      , interval