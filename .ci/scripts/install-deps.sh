sudo apt install lua5.1

# Todo: luarocks version fix
sudo apt install -y luarocks

luarocks --version

sudo luarocks install busted
sudo luarocks install lua-cjson
sudo luarocks install luacov
