# baseline

this is utility script for monome norns, which samples and records audio performance metrics.

## isntallation

instsall via git and **rename the repo folder from `norns-baseline/` to `baseline/`.

## usage

on launch three tests are run immediately:

- 1. softcut test, with all voices at max rate, reading and writing
- 2. supercollider test, where many sinewaves are played
- 3. both

the metrics recorded are JACK server load, and count of xruns reported in each samlping period.

sampling period, sample count, and sinewave count are hardcoded constants at the top of the script. recommended to use as large a sample count as you can stand; the present default is 500 samples at 0.25s period, so the total time to run all tests is 6m15s.

for each test, a `.csv` file records metrics for each sample point, and a `.toml` file records basic statistics and metadata. all files are named with a timestamp and saved to `~/dust/data/baseline`.

(test 3 is presently not very useful, except to verify that the two processes are indepednent: it will be identical to the worst case of tests 1 and 2.)