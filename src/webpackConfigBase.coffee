webpack = require 'webpack'

LANGS = ['en_gb']

module.exports =
  resolve:
    # Add automatically the following extensions to required modules
    extensions: ['', '.coffee', '.cjsx', '.js']

  plugins: [
    new webpack.ContextReplacementPlugin /moment[\\\/]locale$/, new RegExp ".[\\\/](#{LANGS.join '|'})"
    new webpack.DefinePlugin 
      "process.env.NODE_ENV": JSON.stringify process.env.NODE_ENV
  ]

  ## devtool: if process.env.NODE_ENV isnt 'production' then 'eval'

  module:
    loaders: [
      test: /\.cjsx$/
      loader: 'babel!coffee!cjsx'
    ,
      test: /\.coffee$/
      loader: 'babel!coffee'
    ,
      test: /\.(otf|eot|svg|ttf|woff|woff2)(\?v=[0-9]\.[0-9]\.[0-9])?$/
      loader: 'file'
    ,
      test: /\.css$/
      loader: 'style!css'
    ,
      test: /\.sass$/
      loader: 'style!css!sass?indentedSyntax'
    ]
