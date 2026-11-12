# Chronomatron

Chronomatron is a color sequence memory game written in Verilog for the Digilent Nexys A7-100T FPGA board. The game shows a sequence of colors on a VGA monitor. The player memorizes it and repeats it using the board switches.

## Overview

The game has 8 colors and 8 levels. Each level has its own fixed pattern of 8 positions. Every pattern uses all 8 colors once, with no repeats. All patterns are stored in ROM.

As the level goes up, each color is shown for a shorter time. Level 1 shows each color for 1.5 seconds. Level 8 shows each color for only 0.6 seconds.

The design uses these main parts:

* FSM for game flow
* ROM for the level patterns
* Clock based counters for timing
* Switch input with synchronizer, debouncer and edge detection
* VGA display output
* 7 segment display output

## Color and Switch Mapping

Each color is stored as a 3 bit value (000 to 111) and is tied to one switch.

| Switch | Color | Code |
|--------|-------|------|
| SW0 | Red | 000 |
| SW1 | Blue | 001 |
| SW2 | Yellow | 010 |
| SW3 | Green | 011 |
| SW4 | Purple | 100 |
| SW5 | Orange | 101 |
| SW6 | Cyan | 110 |
| SW7 | Pink | 111 |

## Levels

| Level | Name | Time per color |
|-------|------|----------------|
| 1 | Beginner | 1.5 s |
| 2 | Intermediate | 1.4 s |
| 3 | High | 1.3 s |
| 4 | Grand | 1.2 s |
| 5 | Supreme | 1.1 s |
| 6 | Transcendent | 1.0 s |
| 7 | Metaphysic | 0.8 s |
| 8 | Ultrasequencer | 0.6 s |

## Inputs and Outputs

| Name | Type | Use |
|------|------|-----|
| SW0 to SW7 | Input | The 8 color answers |
| SW8 to SW15 | Input | Reserved for future features |
| Push buttons | Input | Start and restart |
| VGA monitor | Output | Colors, countdown, level, game status, result and stats |
| 7 segment display | Output | Level, streak or the position of a wrong answer |

## How to Play

1. Make sure SW0 to SW7 are all OFF.
2. Press the start button.
3. Watch the color sequence on the VGA monitor.
4. When the sequence ends, repeat it by switching on the matching switches in the same order.
5. The system checks your answer and shows correct or incorrect.
6. If correct, switch all of SW0 to SW7 back OFF to move to the next level. Colors will appear faster.
7. Press the restart button to play again.

The switches must be OFF before every round starts. This prevents wrong readings.

## Project Structure

Edit this list to match your real files.

```
Chronomatron/
├── src/
│   ├── top.v              Top module
│   ├── game_fsm.v         Main game FSM
│   ├── pattern_rom.v      ROM with the 8 level patterns
│   ├── timer.v            Clock divider and display time counter
│   ├── input_sync.v       Synchronizer for switches
│   ├── debouncer.v        Debouncer for switches and buttons
│   ├── edge_detect.v      Edge detection
│   ├── vga_controller.v   VGA timing generator
│   ├── vga_display.v      Draws colors, level and status
│   └── seg7_driver.v      7 segment display driver
├── constraints/
│   └── nexys_a7_100t.xdc  Pin constraints
├── sim/
│   └── tb_*.v             Testbenches
├── docs/                  Block diagram, FSM diagram, photos
└── README.md
```

## Requirements

* Digilent Nexys A7-100T board (Artix 7 XC7A100T-1CSG324C)
* Xilinx Vivado (use the version you built with, for example 2022.2)
* VGA monitor and VGA cable
* Micro USB cable for programming

## How to Build

1. Clone the repo.
   ```
   git clone https://github.com/<your-username>/Chronomatron.git
   ```
2. Open Vivado and create a new RTL project.
3. Choose the part `xc7a100tcsg324-1`, or select the Nexys A7-100T board if the board files are installed.
4. Add all files in `src/` as design sources.
5. Add `constraints/nexys_a7_100t.xdc` as the constraints file.
6. Set `top` as the top module.
7. Run Synthesis, then Implementation, then Generate Bitstream.

## How to Run

1. Connect the board to your PC with the USB cable and turn it on.
2. Connect the VGA monitor to the board.
3. In Vivado, open Hardware Manager and click Open Target, then Auto Connect.
4. Click Program Device and select the generated `.bit` file.
5. Set SW0 to SW7 to OFF.
6. Press the start button to begin.

## Simulation

Testbenches are in `sim/`. To run one in Vivado, add the testbench as a simulation source, set it as the simulation top, and click Run Simulation. For quick checks, you can shorten the timing constants so you do not need to wait for real seconds.

## Demo

1. Start the game with the push button.
2. The color sequence plays on the VGA monitor.
3. Repeat the sequence using SW0 to SW7.
4. The monitor shows correct or incorrect.
5. A correct answer moves you to the next level with faster colors.
6. The VGA monitor shows the level, countdown, game status and result. The 7 segment display shows game information.

## Future Enhancements

* 8 seeds, each with its own 8 levels, for 64 patterns in total
* Time Attack mode with a time limit for answering
* High score and best streak
* Sound effects for colors and for correct or wrong answers

## Team

Add your names and student IDs here.

## License

Add a license here, for example MIT.
