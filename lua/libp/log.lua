local global = require("libp.global")("libp")
global.logger = global.logger or require("libp.debug.logger")({ log_file = "libp.log" })

return global.logger
