local sample_lua_module = {}

local cb_factory = require "lua-circuit-breaker.factory"
local circuit_breakers = cb_factory:new()

local settings = {
    version = 1,
    window_time = 10,
    min_calls_in_window= 5,
    failure_percent_threshold= 51,
    wait_duration_in_open_state= 15,
    wait_duration_in_half_open_state= 120,
    half_open_max_calls_in_window= 5,
    half_open_min_calls_in_window= 22,
    notify = function(name, state)
      ngx.log(ngx.ERR,string.format("Breaker [ %s ] state changed to [ %s ]", name, state))
    end,
}

sample_lua_module.get_circuit_breaker = function(name, group)
  local cb, _ = circuit_breakers:get_circuit_breaker(
      name, -- Name of circuit breaker. This should be unique.
      group, -- Used to group certain CB objects into one.
      settings)
  return cb
end


return sample_lua_module
