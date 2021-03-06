# baseline

this is utility script for monome norns, which samples and records audio performance metrics.

## installation

install via git and **rename the repo folder from `norns-baseline/` to `baseline/`**.

## usage

on launch these tests are run in sequence:

- 1. softcut test: all voices reading and writing, modulating rate near maximum
- 2. supercollider test, where many sinewaves are played  (optional, disabled by default)
- 3. both (optional, disabled by default)

the metrics recorded are JACK server load, and count of xruns reported in each sampling period.

sampling period, sample count, and sinewave count are hardcoded constants at the top of the script. recommended to use as large a sample count as you can stand; the present default is 500 samples at 0.25s period, so the total time to run tests 1+2 is ~4 minutes.

for each test, a `.csv` file records metrics for each sample point, and a `.toml` file records basic statistics and metadata. all files are named with a timestamp and saved to `~/dust/data/baseline`.

test 3 is presently not very useful, except to verify that the two processes are indepednent: it will be identical to the worst case of tests 1 and 2. so it is disabled by default (also a constant in script.)

test 2 is potentially useful, but typically the softcut test is sufficient and tests are lengthy, so test 2 is also disabled by default.

note that the **system reverb and compressor are both enabled during all tests.**
