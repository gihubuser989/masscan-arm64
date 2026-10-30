FROM alpine:3.18
RUN apk add --no-cache build-base git linux-headers flex bison wget

# libpcap 1.9.1: static only, optional deps disabled (1.10+ clashes with masscan's pcap_init)
RUN wget -q https://www.tcpdump.org/release/libpcap-1.9.1.tar.gz && \
    tar -xzf libpcap-1.9.1.tar.gz && cd libpcap-1.9.1 && \
    ./configure --disable-shared --enable-static --disable-rdma --disable-dbus \
      --disable-bluetooth --disable-netmap --without-libnl && \
    make -j$(nproc) && make install && cd .. && rm -rf libpcap-1.9.1*

RUN git clone https://github.com/robertdavidgraham/masscan.git /masscan
WORKDIR /masscan
COPY masscan-staticpcap-fix.patch /tmp/fix.patch
RUN git apply /tmp/fix.patch
RUN make -j$(nproc) CFLAGS="-O2 -DSTATICPCAP" LDFLAGS="-static" LIBS="-lm -lpthread -lpcap" && \
    strip bin/masscan
