local function prepare_settings(settings)
	-- TODO: add settings validations
	return {
		name = settings.name,
		interval = settings.window_time,
		open_timeout = settings.wait_duration_in_open_state,
		half_open_timeout = settings.wait_duration_in_half_open_state,
		min_calls_in_window = settings.min_calls_in_window,
		failure_percent_threshold = settings.failure_percent_threshold,
		half_open_min_calls_in_window = settings.half_open_min_calls_in_window,
		half_open_max_calls_in_window = settings.half_open_max_calls_in_window,
		notify = settings.notify or function(state)
        	print(string.format("Breaker %s state changed to: %s", state._state))
    	end,  
		half_open_to_open = settings.half_open_to_open,
		half_open_to_close = settings.half_open_to_close,
		closed_to_open = settings.closed_to_open,
		version = settings.version,
		now = settings.now,
	}
end

return {
	prepare_settings = prepare_settings
}
