# Radio-Frequency
First RF projects

1. Colpitts Oscillator
The file Colpitts_oscillator.m shows the steps to design a 100 kHz oscillator. For other frequencies it is advisable to use:
- C2 = 320e-9, C1 = 470e-9 for 10 kHz and 5 kHz since the L would be to high; k = 3;
- For 100 kHz and 200 kHz use C2 = 32e-9, C1 = 68e-9.

The file sintetizza.m is used in order to synthesize a component:
- if the percentage error < error threshold --> it gives the combination of only 2 components;
- if the percentage error > error threshold --> it gives also the combination of 3 componentes.
