# UART Architecture Documentation

## 1. Design Goal

To implement a hardware UART in Verilog that demonstrates:

* Asynchronous communication handling
* FSM-based protocol implementation
* Clock-enable timing generation
* Oversampling receiver design

---

## 2. System Architecture

The UART consists of three blocks:

```
           +-------------+
clk_50m -->| Baud_gen    |
           +------+------+
                  |
      +-----------+-----------+
      |                       |
+-----v------+         +------v------+
| UART_tx    |         | UART_rx     |
| FSM        |         | Oversampled |
+-----+------+         +------+------+
      | Tx                     | data_out
```

---

## 3. Baud Rate Generator

Instead of generating new clocks, the design uses **clock enable pulses**.

Why?

* Avoids multiple clock domains
* Simplifies timing closure
* FPGA-friendly design

### Divider Equations

TX timing:

```
TX_ACC_MAX = 50 MHz / BAUDRATE
```

RX oversampling timing:

```
RX_ACC_MAX = 50 MHz / (BAUDRATE × 16)
```

Counters wrap and generate enable pulses:

* `Txclk_en` → bit boundary
* `Rxclk_en` → oversample tick

---

## 4. Transmitter Architecture

FSM implementation:

| State    | Function           |
| -------- | ------------------ |
| TX_IDLE  | Wait for enable    |
| TX_START | Send start bit (0) |
| TX_DATA  | Shift out data     |
| TX_STOP  | Send stop bit (1)  |

### Data Flow

```
data_in → shift register → serial Tx
```

---

## 5. Receiver Architecture

Uses **16× oversampling** to recover asynchronous data.

### Sampling Strategy

Each bit period is divided into 16 samples:

```
Sample Count: 0 ... 7 ... 15
                    ↑
               Mid-bit sample
```

The receiver samples at `sample == 8`, the center of the bit.

This improves tolerance to:

* Clock mismatch
* Jitter
* Noise

---

## 6. Receiver FSM

| State    | Purpose           |
| -------- | ----------------- |
| RX_START | Detect start bit  |
| RX_DATA  | Capture 8 bits    |
| RX_STOP  | Validate stop bit |

---

## 7. Testbench Features

The UART design is verified using a self-checking Verilog testbench located at:

```text
./UART/testbench/tb_UART.v
```

The testbench validates the complete **transmit → serial line → receive** datapath using an internal loopback connection.

---

### Loopback-Based Functional Verification

The transmitter output is directly connected to the receiver input:

```text
Tx ─────────► Rx
```

This eliminates the need for an external stimulus model and allows verification of:

* TX FSM serialization
* Baud-rate timing correctness
* RX oversampling and reconstruction
* End-to-end data integrity

---

### Clock Generation

The DUT is driven using a 50 MHz clock, matching the design assumption used by the baud-rate generator:

```verilog
always #10 clk = ~clk;   // 20 ns period → 50 MHz
```

This ensures accurate simulation of baud timing and sampling logic.

---

### Transaction-Based Stimulus Using Tasks

Instead of manually toggling signals, the testbench uses reusable tasks to model UART transactions.

#### `send_byte()`

Encapsulates the transmit handshake:

```verilog
task send_byte(input [7:0] b);
```

Behavior:

1. Waits for a clock edge
2. Places data on `data_in`
3. Pulses `Tx_en` low to start transmission
4. Returns control after the start condition

This mimics a real hardware write request.

---

#### `wait_and_check()`

Implements self-checking receive verification:

```verilog
task wait_and_check(input [7:0] expected);
```

Behavior:

1. Waits for `ready` assertion from UART RX
2. Samples `data_out`
3. Compares received data with expected value
4. Prints **PASS/FAIL** message
5. Clears the `ready` flag via `ready_clr`

This makes the testbench fully automated (no waveform inspection required).

---

### Self-Checking Verification Strategy

Each transmitted byte is validated immediately:

```text
PASS: rx data XX == tx XX
FAIL: rx data XX does not match tx XX
```

The simulation terminates only after all bytes are successfully verified.

This approach ensures:

* Deterministic validation
* Regression-friendly testing
* No manual debugging required for correctness checking

---

### Timed Gaps Between Transactions

Delays are inserted between transmissions:

```verilog
#20000;
```

These gaps:

* Allow the UART frame to complete fully
* Emulate realistic spacing between serial packets
* Prevent back-to-back overruns during verification

---

### Waveform Dump for Debugging

The testbench generates a VCD waveform file:

```verilog
$dumpfile("uart.vcd");
$dumpvars(0, tb_UART);
```

This enables post-simulation inspection of:

* Serial waveform (`Tx`, `Rx`)
* FSM transitions
* Baud clock enable pulses
* Sampling alignment

---

### Built-In Simulation Timeout Protection

A watchdog prevents infinite simulation in case of design failure:

```verilog
#5_000_000;
$display("TIMEOUT: testbench timed out.");
$finish;
```

This ensures automated runs terminate cleanly even if:

* RX never asserts `ready`
* Baud logic stalls
* FSM enters an invalid state

---

### Verification Scope

The current testbench validates:

* Functional TX/RX operation
* Baud-rate generation correctness
* Bit-level serialization/deserialization
* Ready/clear handshake protocol
* End-to-end data transfer accuracy

---

## 8. Timing Relationship

UART is asynchronous — no shared clock exists between devices.

```
External Device ---- async ----> FPGA
```

Oversampling reconstructs the bit timing locally.

---

## 9. Known Design Risks

### Metastability Risk

`Rx` is asynchronous and must be synchronized before use.

### No Error Handling

Receiver assumes valid stop bit and does not report framing errors.

### No Buffering

Only one byte can be handled at a time.

---

## 10. Recommended Hardware Fixes

* Add 2-FF synchronizer:

```
Rx → FF → FF → internal logic
```

* Add FIFO buffering
* Add reset input
* Add parity/framing detection

---

## 11. Learning Outcomes

This project demonstrates:

* Mapping communication protocols into RTL
* Designing FSM-controlled datapaths
* Implementing oversampling receivers
* Generating precise timing using counters
* Structuring synthesizable FPGA modules

---

This UART forms a foundational block for larger digital systems such as microcontrollers, SoCs, and FPGA-based communication interfaces.