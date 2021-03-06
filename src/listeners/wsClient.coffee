socketio    = require 'socket.io-client'
timm        = require 'timm'
treeLines   = require '../gral/treeLines'
k           = require '../gral/constants'

DEFAULT_CONFIG = {}

#-------------------------------------------------
# ## Extension I/O
#-------------------------------------------------
_fExtensionInitialised = false
_fExtensionReady = false

_extensionInit = (config) ->
  return if _fExtensionInitialised
  _fExtensionInitialised = true
  window.addEventListener 'message', (event) ->
    {source, data: msg} = event
    return if source isnt window
    {data: {src, type, data}} = event
    _extensionRxMsg msg
  _extensionTxMsg {type: 'CONNECT_REQUEST'}

_extensionRxMsg = (msg) ->
  {src, type, data} = msg
  return if src isnt 'DT'
  console.log "[PG] RX #{src}/#{type}", data
  switch type
    when 'CONNECT_REQUEST', 'CONNECT_RESPONSE'
      _fExtensionReady = true
      if type is 'CONNECT_REQUEST' 
        _extensionTxMsg {type: 'CONNECT_RESPONSE'}
        if _fSocketConnected
          _extensionTxMsg {type: 'WS_CONNECTED'}
        else
          _extensionTxMsg {type: 'WS_DISCONNECTED'}
      _extensionTxPendingMsgs()
    else
      _socketTxMsg {type, data}
  return

_extensionMsgQueue = []
_extensionTxMsg = (msg) ->
  msg.src = 'PAGE'
  if _fExtensionReady or (msg.type is 'CONNECT_REQUEST')
    _extensionDoTxMsg msg
  else
    _extensionMsgQueue.push msg
_extensionTxPendingMsgs = ->
  return if not _fExtensionReady
  _extensionDoTxMsg msg for msg in _extensionMsgQueue
  _extensionMsgQueue.length = 0
_extensionDoTxMsg = (msg) -> window.postMessage msg, '*'

#-------------------------------------------------
# ## Websocket I/O
#-------------------------------------------------
_socketio = null
_fSocketConnected = false
_socketInit = (config) ->
  {mainStory: story} = config
  story.info 'storyboard', "Connecting to WebSocket server..."
  if not _socketio
    _socketio = socketio.connect k.WS_NAMESPACE
    socketConnected = ->
      story.info 'storyboard', "WebSocket connected"
      _extensionTxMsg {type: 'WS_CONNECTED'}
      _fSocketConnected = true
    socketDisconnected = ->
      story.info 'storyboard', "WebSocket disconnected"
      _extensionTxMsg {type: 'WS_DISCONNECTED'}
      _fSocketConnected = false
    _socketio.on 'connect', socketConnected
    _socketio.on 'reconnect', socketConnected
    _socketio.on 'disconnect', socketDisconnected
    _socketio.on 'error', socketDisconnected
    _socketio.on 'MSG', _socketRxMsg
  _socketio.sbConfig = config

_socketRxMsg = (msg) -> _extensionTxMsg msg
_socketTxMsg = (msg) ->
  if not _socketio
    console.error "Cannot send '#{msg.type}' message to server: socket unavailable"
    return
  _socketio.emit 'MSG', msg

#-------------------------------------------------
# ## Helpers
#-------------------------------------------------
_preprocessAttachments = (record) -> 
  return record if not record.obj?
  return timm.set record, 'obj', treeLines(record.obj)

#-------------------------------------------------
# ## API
#-------------------------------------------------
create = (baseConfig) ->
  config = timm.addDefaults baseConfig, DEFAULT_CONFIG
  listener =
    type: 'WS_CLIENT'
    init: -> 
      _extensionInit config
      _socketInit config
    # Relay records coming from local stories
    process: (record) -> 
      ## console.log "[PG] RX PAGE/RECORDS #{records.length} records"
      _extensionTxMsg {type: 'RECORDS', data: [_preprocessAttachments record]}
    ## config: (newConfig) -> config = timm.merge config, newConfig
  listener

module.exports = {
  create,
}
