package = "host-interpolate-by-header"

version = "1.0.0-1"

supported_platforms = {"linux", "macosx"}
source = {
    url = "git://github.com/dream11/lua-circuit-breaker",
    tag = "v1.0.0"
}

description = {
    summary = "Lua library to implement wrap logic in a circuit breaker",
    homepage = "https://github.com/dream11/lua-circuit-breaker/tree/luarocks-upload",
    license = "MIT",
    maintainer = "Dream11 <tech@dream11.com>"
}

dependencies = {
    "lua >= 5.1"
}

build = {
    type = "builtin",
    modules = {
        ["lua-circuit-breaker.breaker"] = "breaker.lua",
        ["lua-circuit-breaker.counters"] = "counters.lua",
        ["lua-circuit-breaker.errors"] = "errors.lua",
        ["lua-circuit-breaker.factory"] = "factory.lua",
        ["lua-circuit-breaker.oop"] = "oop.lua",
        ["lua-circuit-breaker.utils"] = "utils.lua",
    },
}
