DAMSON = require('./damson').DAMSON

DAMSON.register('text', ((node) -> return node.EN))

console.log DAMSON.render({type:'text',EN:'Hello'})
