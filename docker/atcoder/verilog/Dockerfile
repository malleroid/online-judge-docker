FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

WORKDIR /judge

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        iverilog=12.0-* \
    && rm -rf /var/lib/apt/lists/*

# Smoke test: compile and run a minimal Verilog 2012 program through the TOML's
# exact toolchain (iverilog + vvp) to catch toolchain breakage at image build time.
RUN cd /tmp \
    && printf '%s\n' \
        'module Main;' \
        '    initial begin' \
        '        $display("smoke-ok");' \
        '        $finish;' \
        '    end' \
        'endmodule' \
        > Main.v \
    && iverilog -g2012 -DONLINE_JUDGE -DATCODER Main.v \
    && out=$(vvp -n a.out) \
    && echo "smoke-test output: $out" \
    && echo "$out" | grep -qx "smoke-ok" \
    && rm -f Main.v a.out
