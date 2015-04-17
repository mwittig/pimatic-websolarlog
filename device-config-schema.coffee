module.exports = {
  title: "pimatic-websolarlog device config schemas"
  WebSolarLogProduction: {
    title: "WebSolarLog Production Device"
    description: "Provides energy earnings and current power values of a production device"
    type: "object"
    extensions: ["xConfirm"]
    properties:
      deviceName:
        description: "The name of the Production Device which has been set via WebSolarLog Admin"
        type: "string"
      url:
        description: "URL of the WebSolarLog Server Live page"
        type: "string"
      interval:
        description: "Polling interval for switch state in seconds"
        type: "number"
        default: 0
  }
}