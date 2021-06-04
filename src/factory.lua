local breaker = require "lua-circuit-breaker.breaker"
local utils = require "lua-circuit-breaker.utils"

--[[ 
  Structure of Breaker_factory object will be like
    {
        group_1 = {
            name_1 = cb_object_1,
            name_2 = cb_object_2,
        },
        group_2 = {
            name_3 = cb_object_3,
            name_4 = cb_object_4,
        },
    }
--]]

local Breaker_factory = {}

function Breaker_factory:new(obj)
    obj = obj or {}

    -- https://stackoverflow.com/a/6863008
    -- This line will make o inherit all methods of Breaker_factory.
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Breaker_factory:remove_circuit_breaker(name, group)
    local group_not_exists = self:check_group(group)
    if group_not_exists then
        return false
    end

    self[group][name] = nil
    return true
end

function Breaker_factory:remove_breakers_by_group(group)
    self[group] = nil
    return true
end

function Breaker_factory:get_circuit_breaker(name, group, conf)
    if name == nil or name == "" then
        return nil, "Cannot get circuit breaker without a name"
    end
    
    if group == nil or group == "" then
        group = name
    end

    local group_not_exists = self:check_group(group)
    if group_not_exists then
        self[group] = {}
    end

    -- Update CB object if a CB object is requested with new version of settings
    if self[group][name] == nil or (self[group][name]._version ~= nil and self[group][name]._version < conf.version) then
        local settings, err = utils.prepare_settings(name, conf)
        if err then
            return nil, err
        end
        self[group][name] = breaker.new(settings)
    end

    return self[group][name], nil
end

function Breaker_factory:check_group(group)
    if self[group] == nil then
        return "Trying to access invalid group in circuit breaker factory object: " .. group
    end
end

return Breaker_factory
