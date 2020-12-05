VERSION ?= $(shell ./version.py)
ARCH ?= $(shell uname -i)
COMMIT ?= $(shell git rev-parse HEAD)

export VERSION COMMIT

_LDFLAGS := $(LDFLAGS) -lrt -lpcap -lsodium
_CFLAGS := $(CFLAGS) -Wall -O2 -DWFB_VERSION='"$(VERSION)-$(shell /bin/bash -c '_tmp=$(COMMIT); echo $${_tmp::8}')"'

all_bin: wfb_rx wfb_tx wfb_keygen
all: all_bin gs.key

src/ExternalSources/%.o: src/ExternalSources/%.c src/ExternalSources/*.h
	$(CC) $(_CFLAGS) -std=gnu99 -c -o $@ $<

src/%.o: src/%.cpp src/*.hpp
	$(CXX) $(_CFLAGS) -std=gnu++17 -c -o $@ $<

wfb_rx: src/rx.o src/ExternalSources/radiotap.o src/ExternalSources/fec.o
	$(CXX) -o $@ $^ $(_LDFLAGS)

wfb_tx: src/tx.o src/ExternalSources/fec.o
	$(CXX) -o $@ $^ $(_LDFLAGS)

wfb_keygen: src/keygen.o
	$(CC) -o $@ $^ $(_LDFLAGS)

gs.key: wfb_keygen
	@if ! [ -f gs.key ]; then ./wfb_keygen; fi

clean:
	rm -rf env wfb_rx wfb_tx wfb_keygen dist deb_dist build wifibroadcast.egg-info _trial_temp *~ src/*.o src/ExternalSources/*.o

