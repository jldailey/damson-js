require('./common')

DAMSON.register 'text', (node) -> node.EN

TestGroup 'text',
	text1: () ->
		assertEqual(DAMSON.render({type:'text',EN:'Hello'}), 'Hello')

