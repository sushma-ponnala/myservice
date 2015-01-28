PROJECT = rest_hello_world

DEPS = cowboy emysql jsx sync

dep_cowboy = pkg://cowboy 1.0.0
dep_emysql = https://github.com/Eonblast/Emysql.git master
dep_jsx = https://github.com/talentdeficit/jsx.git master
dep_sync = https://github.com/rustyio/sync.git master

include erlang.mk
