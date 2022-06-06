FROM ubuntu:20.04 as builder

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y cmake clang curl build-essential binutils-dev libunwind-dev libblocksruntime-dev liblzma-dev
RUN curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN ${HOME}/.cargo/bin/rustup default nightly
RUN ${HOME}/.cargo/bin/cargo install honggfuzz

## Add source code to the build stage.
ADD . /parity-scale-codec
WORKDIR /parity-scale-codec/fuzzer

RUN RUSTFLAGS="-Znew-llvm-pass-manager=no" ${HOME}/.cargo/bin/cargo hfuzz build

FROM ubuntu:20.04

COPY --from=builder /parity-scale-codec/fuzzer/hfuzz_target/x86_64-unknown-linux-gnu/release/codec-fuzzer /
COPY --from=builder /parity-scale-codec/fuzzer/hfuzz_target/honggfuzz /usr/local/bin/honggfuzz
COPY --from=builder /usr/lib/x86_64-linux-gnu/libunwind-ptrace.so.0 /usr/lib/x86_64-linux-gnu/libunwind-ptrace.so.0
COPY --from=builder /lib/x86_64-linux-gnu/libopcodes-2.34-system.so /lib/x86_64-linux-gnu/libopcodes-2.34-system.so 
COPY --from=builder /lib/x86_64-linux-gnu/liblzma.so.5 /lib/x86_64-linux-gnu/liblzma.so.5 
COPY --from=builder /usr/lib/x86_64-linux-gnu/libunwind.so.8 /usr/lib/x86_64-linux-gnu/libunwind.so.8
COPY --from=builder /lib/x86_64-linux-gnu/libz.so.1 /lib/x86_64-linux-gnu/libz.so.1 
COPY --from=builder /usr/lib/x86_64-linux-gnu/libunwind-x86_64.so.8 /usr/lib/x86_64-linux-gnu/libunwind-x86_64.so.8
COPY --from=builder /usr/lib/x86_64-linux-gnu/libbfd-2.34-system.so /usr/lib/x86_64-linux-gnu/libbfd-2.34-system.so
RUN mkdir /testsuite && cp /bin/ls /testsuite/seed

ENTRYPOINT ["honggfuzz", "-f", "/tests", "--"]
CMD ["/codec-fuzzer"]

# Package Stage

#COPY --from=builder /goblin/fuzz/target/x86_64-unknown-linux-gnu/release/parse /
