React             = require 'react'
ReactRedux        = require 'react-redux'
actions           = require '../actions/actions'
Icon              = require './910-icon'

RETURN_KEY = 13

mapStateToProps = ({cx: {fLoginRequired, loginState, login}}) -> 
  return {fLoginRequired, loginState, login}
mapDispatchToProps = (dispatch) ->
  onLogIn: (credentials) -> dispatch actions.logIn credentials
  onLogOut: -> dispatch actions.logOut()

Login = React.createClass
  displayName: 'Login'

  #-----------------------------------------------------
  propTypes:
    # From Redux.connect
    fLoginRequired:         React.PropTypes.bool.isRequired
    loginState:             React.PropTypes.string.isRequired
    login:                  React.PropTypes.string
    onLogIn:                React.PropTypes.func.isRequired
    onLogOut:               React.PropTypes.func.isRequired
  getInitialState: ->
    login:                  ''
    password:               ''

  #-----------------------------------------------------
  render: -> 
    {fLoginRequired, loginState} = @props
    if not fLoginRequired
      return <div style={_style.outer()}><i>No login required to see server logs</i></div>
    if loginState is 'LOGGED_IN'
      return @renderLogOut()
    else
      return @renderLogIn()

  renderLogOut: ->
    {login} = @props
    msg = if login then "Logged in as #{login}" else "Logged in"
    <div style={_style.outer()}>
      {msg}
      {' '}
      <Icon 
        icon="sign-out" 
        title="Log out"
        size="lg" 
        fFixedWidth
        onClick={@logOut}
        style={_style.icon()}
      />
    </div>

  renderLogIn: ->
    {loginState} = @props
    btn = switch loginState
      when 'LOGGED_OUT' 
        <Icon 
          icon="sign-in" 
          title="Log in"
          size="lg" 
          fFixedWidth
          onClick={@logIn}
          style={_style.icon()}
        />
      when 'LOGGING_IN' 
        <Icon 
          icon="circle-o-notch" 
          title="Logging in"
          fFixedWidth
          size="lg" 
          style={_style.icon fDisabled: true}
        />
      else ''
    <div style={_style.outer true}>
      <b>Server logs:</b>
      {' '}
      <span>
        <input ref="login"
          id="login"
          type="text"
          value={@state.login}
          placeholder="Login"
          onChange={@onChangeCredentials}
          onKeyUp={@onKeyUpCredentials}
          style={_style.field}
        />
        <input ref="password"
          id="password"
          type="password"
          value={@state.password}
          placeholder="Password"
          onChange={@onChangeCredentials}
          onKeyUp={@onKeyUpCredentials}
          style={_style.field}
        />
        {btn}
      </span>
    </div>

  #-----------------------------------------------------
  logIn: -> @props.onLogIn @state 
  logOut: ->
    @setState {login: '', password: ''}
    @props.onLogOut()

  onKeyUpCredentials: (ev) -> @logIn() if ev.which is RETURN_KEY

  onChangeCredentials: (ev) -> 
    @setState {"#{ev.target.id}": ev.target.value}

#-----------------------------------------------------
_style = 
  outer: (fHighlight) ->
    padding: "4px 10px"
    backgroundColor: if fHighlight then '#d6ecff'
  icon: ({fDisabled} = {}) ->
    cursor: if not fDisabled then 'pointer'
  field:
    marginRight: 4
    width: 70

#-----------------------------------------------------
connect = ReactRedux.connect mapStateToProps, mapDispatchToProps
module.exports = connect Login
