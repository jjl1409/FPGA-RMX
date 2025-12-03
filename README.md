# FPGA-RMX
Audio interface using a Basys-3 FPGA and PMOD I2S2 as our ADC/DAC. Displays detected BPM on seven segment display, amplitude with LEDs, and plays snare on detected beats.

Contains MATLAB models for digital signal processing elements, along with verification testbenches for hardware components.

Initially created as a project for Digital Systems Processing ELEN4810.

## MATLAB
To run informal tests, call tests in Matlab from ./matlab directory. This displays all of the plots for each module.

To generate stimulus files found in ./stimulus(file_name), call generate_stimulus in Matlab from ./matlab directory. This creates csv files for inputs and outputs in order for the verification testbenches to work from a given .wav file, which is placed in ./audio. Note that these stimulus files are already generated, but can be regenerated/run with different files than the ones in the repo.

## VIVADO
The Vivado project can be created by running the build.bat script (or running the TCL). This generates a project in the ./FPGA-RMX directory, which can be then opened in the Vivado GUI by selecting the .xpr project file.

First, the design must be elaborated and subsequently synthesized. Then the project must be implemented, which can all be done through the GUI. Finally, the bitstream must be generated and subsequently programmed onto a connected Basys 3 board using Hardware Manager. No major errors are present, and any critical error indicates an incorrect install/error in the project.

## HARDWARE
The Basys-3 board requires the PMOD I2S2 module to be plugged into the JA header. This can be modified to use the other PMOD headers by editing the constraint file. A line in audio signal must be connected, along with a line out audio signal. Once the board is programmed, it should act as a passthrough with respect to audio.

## VERIFICATION
Testbenches can be run by selecting the correct simulation set in Vivado GUI project settings, which each correspond to a module and its testbench. Run simulation will proceed to create an instance of the module testbench, which will then either generate its own stimulus or load Matlab stimulus files found in ./stimulus.

A test is successful when all outputs match the expected files, which either represents correct functionality or that it perfectly matches the corresponding Matlab module. Note that the top level is simulated, and specific modules that are designed only to work on the hardware (e.g. top-level) do not have testbenches.
