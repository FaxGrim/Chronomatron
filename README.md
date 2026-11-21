# Chronomatron

A color-sequence memory game for the **Digilent Nexys A7-100T**. Pick a seed and play eight levels. Each level shows all eight colors exactly once. Remember the order, then reproduce it with the switches or a compatible USB keyboard.

## Build and program the FPGA

1. Install AMD Vivado with Artix-7 device support. Extract this project to a writable folder.
2. In the Vivado GUI, start with no project open. In **Tcl Console**, change to the extracted project folder and load the project.

   ```tcl
   cd {C:/path/to/Chronomatron}
   source scripts/create_project.tcl
   ```

3. Select **Generate Bitstream**. The project uses device `xc7a100tcsg324-1`, synthesis top `chronomatron_top`, and the included Nexys A7-100T XDC. Check the implementation timing summary after the build.
4. Connect the board's USB programming cable and the board's VGA connector to a VGA monitor. In **Open Hardware Manager → Open Target → Auto Connect**, select **Program Device** and choose `build/chronomatron.runs/impl_1/chronomatron_top.bit`.
5. Optionally connect a wired USB Boot HID keyboard to the board's **USB HOST (J5)** port. The onboard controller presents PS/2 scan-code frames to the FPGA. Board controls are available from startup. A recognized keyboard key sets LD15 and the VGA indicator `KB USED`. The indicator records activity, so unplugging the keyboard does not turn it off automatically.

The equivalent batch build from this folder is:

```sh
vivado -mode batch -source scripts/build.tcl
```

The batch build writes timing and utilization reports under `build/reports/`. The Tcl project script reopens the existing project on later runs.

## Controls and game flow

| Action | Nexys A7 | Keyboard |
| --- | --- | --- |
| Choose seed at the menu | SW10–SW8, a 3-bit value (SW8 is the least significant bit) | F1–F8 select seeds 0–7 |
| Start, continue, or retry | BTND | Enter |
| Return to the seed menu | BTNC | R |
| Select a color during the answer phase | Flip SW0–SW7 from OFF to ON | Top-row keys 1–8 |
| Reset all stats and return to the menu | CPU RESET | — |

1. Select a seed and press **BTND** or **Enter**. The selected seed remains fixed throughout the run. At the menu, a change to the seed switches takes over from a keyboard selection.
2. Set all eight color switches to **OFF**. Wait for the countdown and watch all eight colors. The display time drops by 100 ms per level through level 6, then by 200 ms per level through Ultrasequencer. There is a 180 ms gap between colors.
3. At **YOUR TURN**, enter each color once. A flipped switch can stay ON until the end of the round. Keyboard and switch inputs can be mixed. The palette on VGA is labeled with switch numbers, so palette number 0 corresponds to SW0 or keyboard key 1. Inputs for a color already accepted are ignored. If two new color events arrive on the same clock cycle, the game offers to replay that level.
4. After eight inputs, a correct answer clears the level. Lower the color switches and press **BTND** or **Enter** for the next level. A wrong answer shows the first wrong position (1–8). Press **BTND** or **Enter** to retry from level 1 with the same seed. Clearing level 8 shows **GAME COMPLETED**.
5. **Streak** is the number of consecutive level clears in the current run. **Total Wins** counts all level clears since power-on or CPU reset, including clears on retries, and saturates at 999. Returning to the seed menu clears the streak and keeps Total Wins.

| Color ID | Switch | Key | Color |
| ---: | --- | ---: | --- |
| 0 | SW0 | 1 | Red |
| 1 | SW1 | 2 | Blue |
| 2 | SW2 | 3 | Yellow |
| 3 | SW3 | 4 | Green |
| 4 | SW4 | 5 | Purple |
| 5 | SW5 | 6 | Orange |
| 6 | SW6 | 7 | Cyan |
| 7 | SW7 | 8 | Pink |

| Level | Name | Color time |
| ---: | --- | ---: |
| 1 | Beginner | 1.5 s |
| 2 | Intermediate | 1.4 s |
| 3 | High | 1.3 s |
| 4 | Grand | 1.2 s |
| 5 | Supreme | 1.1 s |
| 6 | Transcendent | 1.0 s |
| 7 | Metaphysic | 0.8 s |
| 8 | Ultrasequencer | 0.6 s |

The seven-segment display shows `S<seed> L<level> <streak><wins>` in normal play, the countdown during countdown, and `E<position>` on an incorrect answer. LD0–LD7 show accepted colors, LD8–LD11 show the number of accepted inputs in binary, LD12 lights in the answer phase, LD13 indicates an incorrect or ambiguous answer, and LD14 indicates a cleared level or completed run.

## Offline seed solver

Open [solver/seed_solver.html](solver/seed_solver.html) in a browser. Pick a seed and a level to see the exact sequence of color names, switches, and keyboard keys. The HTML file is self-contained and can be copied to another computer.

For example, **Seed 0 · Level 1** expects **SW3 → SW1 → SW5 → SW0 → SW7 → SW2 → SW6 → SW4**.

`data/patterns.csv` is the source for both the FPGA ROM and the solver. A seed is a selector for a fixed set of eight patterns. To change the pattern table, edit the CSV and run these commands with Python 3.10 or newer:

```sh
python scripts/generate_patterns.py
python scripts/generate_patterns.py --check
```

The tool verifies that all 64 patterns are distinct permutations of color IDs 0–7. The generated files are included, so a standard build does not require Python.

## HDL architecture

[FSM state diagram (PNG)](docs/Chronomatron_FSM_State_Diagram.png) · [Editable SVG](docs/Chronomatron_FSM_State_Diagram.svg)

| Module | Responsibility |
| --- | --- |
| `chronomatron_top` | Board wiring, reset synchronization, seed selection, input merging and outputs |
| `clock_timer` | 1 ms game/input/display enable and 25 MHz-equivalent pixel enable from the 100 MHz clock |
| `game_fsm` | Menu, preparation, countdown, color display, answer entry, checking and results |
| `sequence_rom` | 64 fixed 24-bit patterns, addressed by the 3-bit seed and 3-bit level index |
| `input_debouncer` | Two-flop synchronization, 12 ms debounce and rising-edge detection for the board controls |
| `ps2_receiver`, `keyboard_controls` | Validate PS/2 frames and decode key presses/releases, suppressing held-key repeats |
| `answer_buffer`, `answer_checker` | Store 8 ordered color IDs in 24 bits, compare against ROM, report the first mismatch |
| `score_tracker` | Streak and BCD Total Wins counters |
| `vga_sync`, `game_renderer`, `font5x7` | 640 × 480 analog VGA at about 59.5 Hz, with frame-coherent game status, text and colors |
| `sevenseg_driver` | Multiplex the board's eight active-low digits |

The ROM stores `8 × 8 × 8 × 3 = 1,536` bits of logical data. Within each word, the first color is in bits `[2:0]`. The answer buffer uses the same order. VGA expands a 3-bit color ID to 4 bits for each of red, green and blue. All sequential logic uses the 100 MHz clock. Clock enables set the pace of the game and advance the VGA counters every fourth cycle.

## Simulation and board verification

Run both included testbenches in Vivado in batch mode:

```sh
vivado -mode batch -source scripts/run_sim.tcl
```

In the GUI, **Run Simulation → Run Behavioral Simulation** runs the game testbench by default. Enter `run all` in the simulator console. To run the video testbench instead, set `tb_video` as the top of **Simulation Sources** before launching.

- `sim/tb_chronomatron.sv` runs all 64 levels using switches and covers keyboard and mixed input, repeats, bad parity, switch bounce, simultaneous inputs, seed locking, wrong-position reporting and score/reset behavior.
- `sim/tb_video.sv` checks a full 800 × 525 raster, sync pulses, active pixels, palette, frame snapshots, and the seven-segment multiplexer.

Delivery verification used Verilator for both testbenches and JavaScript DOM tests for all 64 solver selections. Vivado implementation/timing and the actual board, monitor and keyboard combination should be checked on the target hardware. For a first board check, play Seed 0 Level 1 using the expected order above. Then repeat using keys 1–8, and try a round with positions 3 and 4 swapped to verify `WRONG AT 3` and `E3`.

## References

- [Digilent Nexys A7 Reference Manual](https://digilent.com/reference/_media/reference/programmable-logic/nexys-a7/nexys-a7_rm.pdf), especially the clock, USB HID/PS/2, VGA and basic I/O sections.
- [Digilent Nexys A7-100T Master XDC](https://github.com/Digilent/digilent-xdc/blob/master/Nexys-A7-100T-Master.xdc), used to verify pin assignments and I/O standards.
- [Digilent keyboard board example](https://github.com/Digilent/Nexys-A7-100T-Keyboard), referenced for the host-port setup. Chronomatron implements its own receiver, input rules, game FSM, and rendering.
