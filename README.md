![lua-circuit-breaker](./docs/lua-circuit-breaker.svg)

[![Test](https://github.com/dream11/lua-circuit-breaker/actions/workflows/ci.yml/badge.svg)](https://github.com/dream11/lua-circuit-breaker/actions/workflows/ci.yml)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## Overview
`lua-circuit-breaker` circuit-breaker functionality like [resilience4j](https://github.com/resilience4j/resilience4j) i.e. for Java.
Any IO function can be wrapped around this library.

## How does it work?

1. The library creates a CB(circuit breaker) object for a function.
2. Before making the function call, we call `CB._before()`. This will increment the counter of total_requests by 1.
3. After the function call ends, we call `CB._after(CB._generation, ok)`. If ok is true, success counter is incremented by 1. Otherwise failure counter gets incremented by 1.
4. CB object transitions into 3 states: closed, open and half-open based on the settings defined by the user.

## Installation

### luarocks
```bash
luarocks install lua-circuit-breaker
```

### source
Clone this repo and run:
     luarocks make


## Sample Usage

```lua
--Import Circuit breaker factory.
local circuit_breaker_lib = require "lua-circuit-breaker.factory"

--Create a new instance of the circuit breaker factory. Always set version=0. This is used to flush the circuit breakers when the configuration is changed.
local circuit_breakers = circuit_breaker_lib:new()

-- Get a circuit breaker instance from factory. Returns a new instance only if not already created.
local settings = {
    window_time = 10,
    min_calls_in_window= 20,
    failure_percent_threshold= 51,
    wait_duration_in_open_state= 15,
    wait_duration_in_half_open_state= 120,
    half_open_max_calls_in_window= 10,
    half_open_min_calls_in_window= 5,
    version = 1,
    notify = function(state)
        print(string.format("Breaker %s state changed to: %s", state._state))
    end,
}
local cb, err = circuit_breakers:get_circuit_breaker(
    name, -- Name of circuit breaker. This should be unique.
    group, -- Used to group certain CB objects into one.
    settings,
)

-- Check state of cb. This function returns an error if the state is open or half_open_max_calls_in_window is breached.
local _, err_cb = cb:_before()
if err_cb then
    return false, "Circuit breaker open error"
end
local generation = cb._generation

-- Make the http call for which circuit breaking is required.
local res, err_http = makeHttpCall()

-- Update the state of the cb based on successfull / failure response.
local ok = res and res.status and res.status < 500
cb:_after(generation, ok) -- generation is used to update the counter in the correct time bucket.
```


### Parameters

| Parameter | Type  | Required | description |
| --- | --- | --- | --- |
| `name` | string | true | Name of circuit breaker, this should be unique |
| `group` | string | false | Group to which the CB object will belong |
| `settings.version` | number | true | Maintains version of settings object, changing this will create new CB and flush older CB |
| `settings.window_time` | number | true | Window size in seconds |
| `settings.min_calls_in_window` | number | true | Minimum number of calls to be present in the window to start calculation |
| `settings.failure_percent_threshold` | number | true | % of requests that should fail to open the circuit |
| `settings.wait_duration_in_open_state` | number | true | Duration to wait in seconds before again transitioning to half-open state |
| `settings.wait_duration_in_half_open_state` | number | true | Duration to wait in seconds in half-open state before automatically transitioning to closed state |
| `settings.half_open_max_calls_in_window` | number | true | Maximum calls to allow in half open state |
| `settings.half_open_min_calls_in_window` | number | true | Minimum number of calls to be present in the half open state to start calculation |
| `settings.notify` | function | false | Overrides with a custom logger function |
| `settings.half_open_to_open` | function | false | Overrides transtition from half-open to open state |
| `settings.half_open_to_close` | function | false | Overrides transtition from half-open to closed state |
| `settings.closed_to_open` | function | false | Overrides transtition from closed to open state |


## Available Methods

1. `new()` : create a new circuit breaker factory
2. `get_circuit_breaker(name, group, settings)` : create a new CB object
3. `check_group(group)` : check if this group is present
4. `remove_breakers_by_group(group)` : remove all CB objects in this group
5. `remove_circuit_breaker(name, group)` : remove a particular CB inside a group

## Inspired by
- [moonbreaker](https://github.com/Invizory/moonbreaker)
- [resilience4j](https://github.com/resilience4j/resilience4j)
