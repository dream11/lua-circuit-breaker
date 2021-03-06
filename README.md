![lua-circuit-breaker](./docs/lua-circuit-breaker.svg)

[![Continuous Integration](https://github.com/dream11/lua-circuit-breaker/actions/workflows/ci.yml/badge.svg)](https://github.com/dream11/lua-circuit-breaker/actions/workflows/ci.yml)
[![Code Coverage](https://codecov.io/gh/dream11/lua-circuit-breaker/branch/master/graph/badge.svg?token=6wyFuRgmdG)](https://codecov.io/gh/dream11/lua-circuit-breaker)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## Overview
`lua-circuit-breaker` provides circuit-breaker functionality like [resilience4j](https://github.com/resilience4j/resilience4j) i.e. for Java.
<br>Any IO function/method that can fail can be wrapped around `lua-circuit-breaker` and can be made to fail fast, leading to improved resiliency and fault tolerance.

## How does it work?

1. The library creates a CB(circuit breaker) object for a function.
2. Before making the function call, we call `CB._before()`. This will return an error if the circuit breaker is in open state otherwise will increment the counter of total_requests by 1.
3. After the function call ends, we call `CB._after(CB._generation, ok)`. If ok is true, the success counter is incremented by 1. Otherwise, the failure counter gets incremented by 1.
4. CB object transitions into three states: closed, open, and half-open based on the settings defined by the user.

## Installation

### luarocks
```bash
luarocks install lua-circuit-breaker
```

### source
Clone this repo and run:
```bash
luarocks make
```


## Sample Usage

```lua
--Import Circuit breaker factory.
local circuit_breaker_lib = require "lua-circuit-breaker.factory"

--Create a new instance of the circuit breaker factory. Always set version = 0. This is used for flushing the circuit breakers when the configuration is changed.
local circuit_breakers = circuit_breaker_lib:new()

-- Get a circuit breaker instance from factory. Returns a new instance only if not already created.
local settings = {
    version = 1,
    window_time = 10,
    min_calls_in_window= 20,
    failure_percent_threshold= 51,
    wait_duration_in_open_state= 15,
    wait_duration_in_half_open_state= 120,
    half_open_max_calls_in_window= 10,
    half_open_min_calls_in_window= 5,
    notify = function(name, state)
        print(string.format("Breaker [ %s ] state changed to [ %s ]", name, state))
    end,
}
local cb, err = circuit_breakers:get_circuit_breaker(
    "io_call_x", -- Name of circuit breaker. This should be unique.
    "io_calls", -- Used to group certain CB objects into one.
    settings,
)

-- Check state of cb. This function returns an error if the state is open or half_open_max_calls_in_window is breached.
local _, err_cb = cb:_before()
if err_cb then
    return false, "Circuit breaker open error"
end
local generation = cb._generation

-- Call IO method for which circuit breaking is required.
local res, err_http = makeIOCall()

-- Update the state of the cb based on successful / failure response.
local ok = res and res.status and res.status < 500
cb:_after(generation, ok) -- generation is used to update the counter in the correct time bucket.
```

## Openresty Sample Usage

There is a sample nginx openresty application (using docker for ease of usage) on [`ngx_lua_sample`](ngx_lua_sample/README.md)

### Parameters

| Key | Default  | Type  | Required | Description |
| --- | --- | --- | --- | --- |
| name | NA | string | true | Name of circuit breaker, this should be unique |
| group | "default_group" | string | false | Group to which the CB object will belong |
| settings.version | NA | number | true | Maintains version of settings object, changing this will create new CB and flush older CB |
| settings.window_time | 10 | number | true | Window size in seconds |
| settings.min_calls_in_window | 20 | number | true | Minimum number of calls to be present in the window to start calculation |
| settings.failure_percent_threshold | 51 | number | true | % of requests that should fail to open the circuit |
| settings.wait_duration_in_open_state | 15 | number | true | Duration(sec) to wait before automatically transitioning from open to half-open state |
| settings.wait_duration_in_half_open_state | 120 | number | true | Duration(sec) to wait in half-open state before automatically transitioning to closed state |
| settings.half_open_min_calls_in_window | 5 | number | true | Minimum number of calls to be present in the half open state to start calculation |
| settings.half_open_max_calls_in_window | 10 | number | true | Maximum calls to allow in half open state |
| settings.half_open_to_open | NA | function | false | Overrides transition from half-open to open state |
| settings.half_open_to_close | NA | function | false | Overrides transition from half-open to closed state |
| settings.closed_to_open | NA | function | false | Overrides transtition from closed to open state |
| settings.notify | NA | function | false | Overrides with a custom logger function |


## Available Methods

1. `new()` : create a new circuit breaker factory
2. `get_circuit_breaker(name, group, settings)` : create a new CB object
3. `check_group(group)` : check if this group is present
4. `remove_breakers_by_group(group)` : remove all CB objects in a group
5. `remove_circuit_breaker(name, group)` : remove a particular CB inside a group. if group is not passed, "default_group" is assumed.

## Inspired by
- [moonbreaker](https://github.com/Invizory/moonbreaker)
- [resilience4j](https://github.com/resilience4j/resilience4j)
