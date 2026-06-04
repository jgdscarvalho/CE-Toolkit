<p align="center">
  <img src=".github/banner.png">
</p>

# CE Toolkit

Personal collection of Cheat Engine and Lua scripts for reverse engineering, memory analysis, runtime inspection, and modding of retro games, intended for research and documentation.

## Requirements

- [Cheat Engine](https://www.cheatengine.org/)  
  A basic understanding of Cheat Engine is recommended, including how to load memory tables, execute Lua scripts, and inspect memory structures.

- [PCSX2](https://pcsx2.net/) (for PlayStation 2)  
  All scripts were developed and tested using the PCSX2 emulator. While other PlayStation 2 emulators may work, compatibility is not guaranteed.

## Usage

To run a script, open the Lua Engine in Cheat Engine while the game is running, then copy and paste the script into the editor and execute it.

Before running a script, make sure to read the instructions provided in the source file. Important information such as the required game state, menu, or screen is documented in comments near the end of the file, directly above the `run()` function.

Following these instructions is recommended, as some scripts rely on specific memory states or game contexts to function correctly.
