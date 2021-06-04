local Counters = require "lua-circuit-breaker.counters"
local errors = require "lua-circuit-breaker.errors"
local oop = require "lua-circuit-breaker.oop"
local CircuitBreaker = oop.class()

local states = {
	closed = "closed",
	open = "open",
	half_open = "half_open"
}

function CircuitBreaker:__new(settings) -- luacheck: ignore 561
	settings = settings or {}
	local expiry = (settings.now or os.time)() + settings.interval

	return {
		_name = settings.name,
		_version = settings.version,
		_half_open_max_calls_in_window = settings.half_open_max_calls_in_window,
		_half_open_timeout = settings.half_open_timeout or 120,
		_open_timeout = settings.open_timeout or 60,
		_interval = settings.interval or 0,
		_min_calls_in_window = settings.min_calls_in_window,
		_closed_to_open = settings.closed_to_open or
			function(counters)
				return counters:total_samples() >= settings.min_calls_in_window and
					(counters.total_failures / counters:total_samples()) * 100 >= settings.failure_percent_threshold
			end,
		_half_open_to_close = settings.half_open_to_close or
			function(counters)
				return counters:total_samples() >= settings.half_open_min_calls_in_window and
					(counters.total_failures / counters:total_samples()) * 100 < settings.failure_percent_threshold
			end,
		_half_open_to_open = settings.half_open_to_open or
			function(counters)
				return counters:total_samples() >= settings.half_open_min_calls_in_window and
					(counters.total_failures / counters:total_samples()) * 100 >= settings.failure_percent_threshold
			end,
		_now = settings.now or os.time,
		_notify = settings.notify,
		_state = states.closed,
		_counters = Counters(),
		_generation = 0,
		_expiry = expiry,
		_last_state_notified = true,
	}
end

function CircuitBreaker:state()
	self:_update_state()
	return self._state
end

function CircuitBreaker:_before()
	self:_update_state()
	if self._state == states.open then
		return false, errors.open
	elseif self._state == states.half_open and self._counters.requests >= self._half_open_max_calls_in_window then
		return false, errors.too_many_requests
	end
	self._counters:_on_request()

	return true
end

function CircuitBreaker:_after(previous_generation, is_success)
	self:_update_state()

	if self._generation ~= previous_generation then
		return
	end

	if is_success then
		self:_on_success()
	else
		self:_on_failure()
	end
end

function CircuitBreaker:_update_state()
	-- If window has not expired
	if (self._expiry > self._now()) then
		return
	end

	if self._state == states.closed then
		self:_next_generation()
	elseif self._state == states.half_open then
		self:_set_state(states.closed)
		print("Transition: Half Open to Closed due to wait_duration_in_half_open_state, breaker name: ", self._name)
	else
		print("Transition: Open to Half Open, breaker name: ", self._name)
		self:_set_state(states.half_open)
	end
end

function CircuitBreaker:_on_success()
	self._counters:_on_success()
	-- Todo: change state in half-open state when minimum calls in window to calculate % are elapsed
	if self._state == states.half_open then
		if self._half_open_to_close(self._counters) then
			self:_set_state(states.closed)
		end
		if self._half_open_to_open(self._counters) then
			self:_set_state(states.open)
		end
	end
end

function CircuitBreaker:_on_failure()
	self._counters:_on_failure()
	if self._state == states.closed and self._closed_to_open(self._counters) then
		print("Transition: Close to Open, breaker name: ", self._name)
		self:_set_state(states.open)
	end
	-- Change state in half-open state when minimum calls in window to calculate % are elapsed
	if self._state == states.half_open then
		if self._half_open_to_close(self._counters) then
			print("Transition: Half Open to Close, breaker name: ", self._name)
			self:_set_state(states.closed)
		end
		if self._half_open_to_open(self._counters) then
			print("Transition: Half Open to Open, breaker name: ", self._name)
			self:_set_state(states.open)
		end
	end
end

function CircuitBreaker:_set_state(new_state)
	self._state = new_state
	self._last_state_notified = false
	self:_next_generation()
	local cb_name = self._name
	self:_notify(cb_name, new_state)
end

function CircuitBreaker:_next_generation()
	self._generation = self._generation + 1
	self._counters = Counters()
	self._expiry = 0

	if self._state == states.open then
		self._expiry = self._now() + self._open_timeout
	elseif self._state == states.half_open then
		self._expiry = self._now() + self._half_open_timeout
	else
		self._expiry = self._now() + self._interval
	end
end

return {
	new = CircuitBreaker,
	states = states
}
