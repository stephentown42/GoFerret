# Two-choice Timbre Discrimination Task

## Stages:

Much of the code for each level follows the same basic logic in which the program is in one of four states:

* *PrepareStim* : Generating stimuli, assigning and reseting relevant variables for next trial
* *WaitForStart*: Checking the circuit to determine when the subject has initiated a trial by holding at the centre spout for a minimum amount of time
* *WaitForResponse*: Checking the circuit to determine if a response has been made at a peripheral location, or abort trial if too much time has elapsed
* *Timeout*: Waiting for a set period following an error, before allowing the next trial

## Training levels:

Each level represents a protocol for running trials while shaping the initial behavior. Increasing level number reflects the advancement of the subject towards the point when they're ready for testing.

* [Level_01](https://github.com/stephentown42/Perceptual_Constancy_for_Vowels/blob/main/behavioral_task/GoFerret/ST_TimbreDiscrimination/stages/level01.m): No sounds, rewards at all spouts
* [Level_02](https://github.com/stephentown42/Perceptual_Constancy_for_Vowels/blob/main/behavioral_task/GoFerret/ST_TimbreDiscrimination/stages/level02.m): Tbc
* [Level_03](https://github.com/stephentown42/Perceptual_Constancy_for_Vowels/blob/main/behavioral_task/GoFerret/ST_TimbreDiscrimination/stages/level03.m): Tbc
* [Level_04](https://github.com/stephentown42/Perceptual_Constancy_for_Vowels/blob/main/behavioral_task/GoFerret/ST_TimbreDiscrimination/stages/level04.m): Tbc
* [Level_05](https://github.com/stephentown42/Perceptual_Constancy_for_Vowels/blob/main/behavioral_task/GoFerret/ST_TimbreDiscrimination/stages/level05.m): Tbc
* [Level_06](https://github.com/stephentown42/Perceptual_Constancy_for_Vowels/blob/main/behavioral_task/GoFerret/ST_TimbreDiscrimination/stages/level06.m): Tbc

## Test levels:

Each level represents a different testing condition; the trial protocols are largely the same but the stimuli may vary in different ways (e.g. one vs. multiple stimulus presentations, different fundamental frequencies etc.)

* Vowels varying in fundamental frequency: 
  * [Level 07](https://github.com/stephentown42/Perceptual_Constancy_for_Vowels/blob/main/behavioral_task/GoFerret/ST_TimbreDiscrimination/stages/level07.m) (two tokens)
  * [Level 17](https://github.com/stephentown42/Perceptual_Constancy_for_Vowels/blob/main/behavioral_task/GoFerret/ST_TimbreDiscrimination/stages/level17.m) (two tokens)
  * [Level 37](https://github.com/stephentown42/Perceptual_Constancy_for_Vowels/blob/main/behavioral_task/GoFerret/ST_TimbreDiscrimination/stages/level37.m) (one token)
* Vowels varying in sound level: [Level 16](https://github.com/stephentown42/Perceptual_Constancy_for_Vowels/blob/main/behavioral_task/GoFerret/ST_TimbreDiscrimination/stages/level16.m)
* Vowels varying in sound location: [Level 23](https://github.com/stephentown42/Perceptual_Constancy_for_Vowels/blob/main/behavioral_task/GoFerret/ST_TimbreDiscrimination/stages/level23_spatial.m)
* Voiceless (whispered) vowels: [Level 09](https://github.com/stephentown42/Perceptual_Constancy_for_Vowels/blob/main/behavioral_task/GoFerret/ST_TimbreDiscrimination/stages/level09.m)


## Toolbox

Contains scripts for generating synthetic vowel sounds with different fundamental frequencies, or unvoiced vowels.

### Compatibility:
Note that this code was designed for Matlab before the 2014 changes to the graphics system. We've encountered problems since then running version 1.0.0 on versions of Matlab after 2013b, as well as on Windows 10. A revised version (GoFerret 2.0.0) has been implemented for Windows 10 and can run on Matlab 2014 or later, but this was not used for this project - please contact @stephentown42 if you need more recent versions.
