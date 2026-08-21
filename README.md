# FPGA Digital Systems Labs

Selected Verilog course projects for Intel MAX 10 devices. This repository keeps handwritten RTL, Quartus project settings and available waveform/test-vector files while excluding generated databases and large demonstration videos.

## Highlights

| Directory | Design |
|---|---|
| `projects/cpu` | 8-bit teaching CPU with program counter, instruction memory, register file, ALU and controller |
| `projects/EXP5` | Password-box finite-state machine with debounced keys, password update and alarm state |
| `projects/serial_adder` | Serial binary adder |
| `projects/ram` | RAM experiment |
| `projects/ic74HC595` | 74HC595-style serial output logic |
| `projects/keyCounter` / `cnt60s` | Key and time counters |
| `projects/breathingLED` / `tailLight` | PWM breathing LED and vehicle tail-light sequence |
| Other directories | Flip-flop, selector, shift-register, seven-segment and full-adder fundamentals |

Most labs target `10M02SCM153C8G`; the CPU project targets `10M08SCM153I7G`.

## Open in Quartus

Open the `.qpf` file inside a project directory, review the pin assignments in its `.qsf`, then compile for the configured device. Pin mappings are board-specific and must be checked before programming another board.

## Verification status

- Curated source and project files are present.
- Generated Quartus results were deliberately excluded.
- A fresh synthesis/programming run has not been performed during portfolio preparation.
