## Nginx Lua (openresty usage)

### Docker
```bash
make up # it'll start serving on port 8080 (service) and 9090 (upstream service)
http "http://localhost:8080/lua_content" # it fetches content from 9090 with no error

# Let's inject a 1.5s timeout (the http client on 8080 is configured to timeout on 300ms)
http "http://localhost:9090/commands?timeout=1500"

# if we try to fetch from the upstream, it'll delay but it's going to work
http "http://localhost:9090/lua_content"
# but if we try to fetch from the service
http "http://localhost:8080/lua_content" # it'll fail due to the timeout


# now, let's force a open circuit state
watch -n 0.1 http "http://localhost:8080/lua_content"

# from time to time we'll see the cb trying to restablish the service

# if you want to make the service back delete the timeout rule
http DELETE "http://localhost:9090/commands?timeout=1500"
```
