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
    half_open_min_calls_in_window= 2,
    notify = function(state, name)
      ngx.log(ngx.ERR,string.format("Breaker [ %s ] state changed to [ %s ]", name, state._state))
    end,
}

-- On 10s window_time, after min_calls_in_window 5, check if failure rate is above failure_percent_threshold.
-- If it is, then change state to open. Wait at least 15s (wait_duration_in_open_state) to try the half_open state.
-- In half_open state wait 120s or min 2 to max 5 requests.

sample_lua_module.get_circuit_breaker = function(name, group)
  local cb, _ = circuit_breakers:get_circuit_breaker(
      name, -- Name of circuit breaker. This should be unique.
      group, -- Used to group certain CB objects into one.
      settings)
  return cb
end


return sample_lua_module
