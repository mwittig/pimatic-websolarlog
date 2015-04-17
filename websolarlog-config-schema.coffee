module.exports = {
  title: "pimatic-websolarlog plugin config options"
  type: "object"
  properties:
    interval:
      description: "Polling interval for switch state in seconds"
      type: "number"
      default: 30
    debug:
      description: "Debug mode. Writes debug message to the pimatic log"
      type: "boolean"
      default: false
}