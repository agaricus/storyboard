{storyboard, expect, sinon, Promise} = require './imports'
consoleListener = require '../../lib/listeners/console'

{mainStory} = storyboard

#-====================================================
# ## Tests
#-====================================================
describe "consoleListener", ->

  _listener = null
  _spyLog   = null
  _spyError = null
  before -> 
    storyboard.removeAllListeners()
    storyboard.addListener consoleListener
    storyboard.config filter: '*:*'
    _listener = storyboard.getListeners()[0]
    _spyLog   = sinon.spy()
    _spyError = sinon.spy()
    consoleListener._setConsole 
      log: _spyLog
      error: _spyError

  beforeEach -> 
    _spyLog.reset()
    _spyError.reset()

  it "should output log lines", ->
    mainStory.info "testSrc", "Test message"
    expect(_spyLog).to.have.been.calledOnce
    msg = _spyLog.args[0][0]
    expect(msg).to.contain 'testSrc'
    expect(msg).to.contain 'INFO'
    expect(msg).to.contain 'Test message'

  it "should use console.error for errors", ->
    mainStory.error "testSrc", "Test error"
    expect(_spyLog).not.to.have.been.called
    expect(_spyError).to.have.been.calledOnce
    msg = _spyError.args[0][0]
    expect(msg).to.contain 'ERROR'
    expect(msg).to.contain 'Test error'

  it "should report creation of a story", ->
    childStory = mainStory.child {title: "Three piggies"}
    expect(_spyLog).to.have.been.calledOnce
    msg = _spyLog.args[0][0]
    expect(msg).to.contain '[CREATED]'

  describe "object attachments", ->

    it "should use JSON.stringify with inline attachments", ->
      obj = {a: 5}
      mainStory.info "Inline attachment", {attach: obj, attachInline: true}
      expect(_spyLog).to.have.been.calledOnce
      msg = _spyLog.args[0][0]
      expect(msg).to.contain JSON.stringify obj

    it "when JSON.stringify is impossible, it should expand the object tree", ->
      obj = {oneAttr: 5}
      obj.b = obj
      mainStory.info "Inline attachment with circular ref", attach: obj
      expect(_spyLog).to.have.been.calledThrice
      expect(_spyLog.args[0][0]).to.contain "circular ref"
      expect(_spyLog.args[1][0]).to.contain "oneAttr"
      expect(_spyLog.args[2][0]).to.contain "[CIRCULAR]"

    it "should also allow the user to always expand an attachment", ->
      obj = {attr1: 8}
      mainStory.info "Expanded attachment", {attach: obj, attachLevel: 'TRACE', attachExpanded: true}
      expect(_spyLog).to.have.been.calledTwice
      expect(_spyLog.args[0][0]).to.contain "INFO"
      expect(_spyLog.args[0][0]).to.contain "Expanded attachment"
      expect(_spyLog.args[1][0]).to.contain "TRACE"
      expect(_spyLog.args[1][0]).to.contain "attr1"

  describe "in relative-time mode", ->

    before -> _listener.config relativeTime: true
    after  -> _listener.config relativeTime: false

    it "should include an ellipsis when more than 1s ellapses between lines", ->
      mainStory.info "Msg A"
      Promise.delay 1100
      .then ->
        mainStory.info "Msg B"
        expect(_spyLog).to.have.callCount 3
        args = _spyLog.args
        expect(args[0][0]).to.contain "Msg A"
        expect(args[1][0]).to.contain "..."
        expect(args[2][0]).to.contain "Msg B"
