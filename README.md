# UART (Universal Asynchronous Receiver/Transmitter) — Verilog Implementation

## Overview

This project implements a simple **UART** in Verilog using a 50 MHz system clock and a default baud rate of **115200 bps**.

The design demonstrates:

* UART transmission (TX) using a finite state machine
* UART reception (RX) using **16× oversampling**
* Baud-rate generation using clock-enable pulses (no derived clocks)
* Clean modular RTL structure suitable for FPGA implementation

This project is intended for **learning digital communication, FSM design, and RTL architecture**.

> For full technical details, see `docs/architecture.md`.

---

## UART Frame Format (8N1)

| Field     | Bits | Value     |
| --------- | ---- | --------- |
| Start Bit | 1    | 0         |
| Data Bits | 8    | LSB first |
| Parity    | —    | None      |
| Stop Bit  | 1    | 1         |

---

## Module Summary

### Baud_gen

Generates timing enables derived from the 50 MHz clock.

Outputs:

* `Txclk_en` → 1 pulse per bit period (TX timing)
* `Rxclk_en` → 16 pulses per bit period (RX oversampling)

---

### UART_tx

Implements transmission using a 4-state FSM:

* TX_IDLE  → wait for transmit request
* TX_START → send start bit
* TX_DATA  → shift out 8 bits
* TX_STOP  → send stop bit

Outputs `Tx_busy` while transmitting.

---

### UART_rx

Implements reception using **16× oversampling**:

* Detects start edge
* Samples each bit at its midpoint
* Reconstructs byte
* Raises `ready` when data is valid

---

### UART_top

Connects the baud generator, transmitter, and receiver.

---

## How It Works

1️⃣ Baud generator creates enable pulses instead of new clocks.
2️⃣ TX changes output only when `Txclk_en` (active-low enable) is asserted.
3️⃣ RX samples input using `Rxclk_en` (active-low enable) (16× faster).
4️⃣ Oversampling allows tolerance to baud mismatch and noise.

---

## ▶️ How to Run (Using Icarus Verilog)

### 1️⃣ Compile

From inside the `UART/` directory:

```bash
iverilog -o uart_sim \
rtl/Baud_gen.v \
rtl/UART_tx.v \
rtl/UART_rx.v \
rtl/UART_top.v \
testbench/tb_UART.v
```

---

### 2️⃣ Run Simulation

```bash
vvp uart_sim
```

Expected console output:

```text id="expected"
SUCCESS: all bytes verified
```

If any mismatch occurs, the testbench prints:

```text id="fail"
FAIL: rx data XX does not match tx XX
```

---

### 3️⃣ View Waveforms (GTKWave)

The testbench generates a VCD dump:

```text id="vcd"
uart.vcd
```

Open it with:

```bash
gtkwave uart.vcd
```

Recommended signals to inspect:

* `Tx`
* `Rx`
* `Tx_busy`
* `ready`
* `Rx_data`
* `dut.*` (internal FSM + baud counters)

---

## Intended Use

* FPGA prototyping
* Digital design learning
* UART debugging interface
* Foundation block for SoC / processor projects

---

## 📘 Detailed Architecture

A complete explanation of the UART design, including baud-rate generation, TX/RX state machines, oversampling-based reception, and timing considerations, is available here:

➡️ [Architecture Documentation](docs/architecture.md)

---

## Limitations (Current Version)

This version is intentionally minimal and should be improved for real hardware:

* ❌ Rx input is not synchronized (metastability risk)
* ❌ No reset input (uses `initial` blocks)
* ❌ No buffering (single-byte operation)
* ❌ No framing or overrun error detection
* ❌ Fixed 8N1 (8 data bits, no parity, 1 stop bit) format

---

## Future Work

* Add synchronous reset (active-low)
* Add **2-flip-flop synchronizer** on `Rx` (drastically reduces metastability risk)
* Add FIFO buffering
* Add parity and error detection
* Parameterize clock frequency

---

## Author

Priyansh
ECE — PDEU
Focus: Digital Design • VLSI • Computer Architecture