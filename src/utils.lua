local function prepare_settings(name, settings)
	if settings.version == nil then
		return nil, "version is required in settings"
	end

	if name == nil or name == "" then
		return nil, "name is required in settings"
	end

	return {
		name = name,
		version = settings.version,
		interval = settings.window_time or 10,
		min_calls_in_window = settings.min_calls_in_window or 20,
		failure_percent_threshold = settings.failure_percent_threshold or 51,
		open_timeout = settings.wait_duration_in_open_state or 15,
		half_open_timeout = settings.wait_duration_in_half_open_state or 120,
		half_open_min_calls_in_window = settings.half_open_min_calls_in_window or 5,
		half_open_max_calls_in_window = settings.half_open_max_calls_in_window or 10,
		notify = settings.notify or function(self, breaker_name, new_state)
        	print(string.format("Breaker [ %s ] state changed to [ %s ]", breaker_name, new_state))
    	end,  
		half_open_to_open = settings.half_open_to_open,
		half_open_to_close = settings.half_open_to_close,
		closed_to_open = settings.closed_to_open,
		now = settings.now,
	}, nil
end

return {
	prepare_settings = prepare_settings
}
