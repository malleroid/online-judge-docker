FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

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
