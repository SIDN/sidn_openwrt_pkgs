all: check

test:
	lua ./tests/request_tester.lua

FILES=autonta.lua autonta_util.lua config.lua language_keys.lua mio.lua set_pass.lua update_system.lua valibox_update.lua
check:
	for n in $(FILES); do \
	    luacheck $$n --no-max-line-length --no-unused ;\
	done
