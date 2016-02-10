# #WebSolarLog plugin

module.exports = (env) ->

  # Require the bluebird promise library
  Promise = env.require 'bluebird'

  # Require the nodejs net API
  net = require 'net'

  url = require 'url'

  wsl = require 'node-websolarlog'

  # ###WebSolarLogPlugin class
  class WebSolarLogPlugin extends env.plugins.Plugin

    # ####init()
    # The `init` function is called by the framework to ask your plugin to initialise.
    #  
    # #####params:
    #  * `app` is the [express] instance the framework is using.
    #  * `framework` the framework itself
    #  * `config` the properties the user specified as config for your plugin in the `plugins` 
    #     section of the config.json file 
    #     
    # 
    init: (app, @framework, @config) =>
      # register devices
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("WebSolarLogProduction", {
        configDef: deviceConfigDef.WebSolarLogProduction,
        createCallback: (config) =>
          return new WebSolarLogProductionDevice(config, this)
      })


  class WebSolarLogBaseDevice extends env.devices.Device
    # Initialize device by reading entity definition from middleware
    constructor: (@config, @plugin) ->
      @debug = plugin.config.debug;
      env.logger.debug("WebSolarLogBaseDevice Initialization") if @debug
      @id = config.id
      @name = config.name

      parts = url.parse(config.url, false, true)
      if !parts.hostname?
        env.logger.error("Device URL must contain a hostname")
        @deviceConfigurationError = true;

      @options = {}
      @options.name = config.deviceName || config.name
      @options.host = parts.hostname
      @options.path = parts.path if parts.path?
      @options.port = parts.port if parts.port?
      @options.protocol = parts.protocol if parts.protocol?
      @interval = 1000 * (config.interval or plugin.config.interval)
      super()

      if !@deviceConfigurationError
        @_scheduleUpdate()


    # poll device according to interval
    _scheduleUpdate: () ->
      if typeof @intervalObject isnt 'undefined'
        clearInterval(@intervalObject)

      # keep updating
      if @interval > 0
        @intervalObject = setInterval(=>
          @_requestUpdate()
        , @interval
        )

      # perform an update now
      @_requestUpdate()

    _requestUpdate: ->
      id = @id
      wsl.getProductionDeviceData(@options).then((values) =>
        @emit "productionData", values
      ).catch((error) ->
        env.logger.error("Unable to get production data form device id=" + id + ": " + error.toString())
      )

    _setAttribute: (attributeName, value) ->
      if @[attributeName] isnt value
        @[attributeName] = value
        @emit attributeName, value


  class WebSolarLogProductionDevice extends WebSolarLogBaseDevice
    # attributes
    attributes:
      currentPower:
        description: "AC Power (Phase 1)"
        type: "number"
        unit: 'W'
        acronym: 'GP'
      currentAmperage:
        description: "AC Amperage (Phase 1)"
        type: "number"
        unit: 'A'
        acronym: 'GA'
      currentVoltage:
        description: "AC Voltage (Phase 1)"
        type: "number"
        unit: 'V'
        acronym: 'GV'

    currentPower: 0.0
    currentAmperage: 0.0
    currentVoltage: 0.0

    # Initialize device by reading entity definition from middleware
    constructor: (@config, @plugin) ->
      env.logger.debug("WebSolarLogProductionDevice Initialization") if @debug

      @on 'productionData', ((values) ->
        if (values.data?)
          @_setAttribute('currentPower', Number values.data.GP) if values.data.GP?
          @_setAttribute('currentAmperage', Number values.data.GA) if values.data.GA?
          @_setAttribute('currentVoltage', Number values.data.GV) if values.data.GV?
      )
      super(@config, @plugin)

    getCurrentPower: -> Promise.resolve @currentPower
    getCurrentAmperage: -> Promise.resolve @currentAmperage
    getCurrentVoltage: -> Promise.resolve @currentVoltage

  # ###Finally
  # Create a instance of my plugin
  myPlugin = new WebSolarLogPlugin
  # and return it to the framework.
  return myPlugin