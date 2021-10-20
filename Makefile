all: build

build:
	shards build

run: bin/pcal2md
	bin/pcal2md

install: bin/pcal2md
	cp -v bin/pcal2md ~/bin

clean:
	rm -Rvf bin

