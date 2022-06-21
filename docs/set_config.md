# Set Configuration

To run GoFerret on a new machine, update the relevant paths and settings for your device

## Paths
* **home_dir**: Directory containing GoFerret (allows the program to be called even when not current working directory)
* **save_dir**: Directory in which to save data, must containing folders for each subject (e.g. F1201, F2011 etc.)
* **tank_parent**: Directory in which TDT tanks / blocks are saved
* **weight_dir**: Directory in which weight metadata is kept
* **high_res_video**: Optional, path to video recording script in python
* **split_screen_video**: Optional, path to video recording script in python

<br>

## Settings
* **stimDevice**: Name of stimulus generation device (see OpenWorkBench tutorial for more information)
* **recDevice**: Name of neural recording device (see OpenWorkBench tutorial for more information)
* **recFerrets**: List of subjects in which to record data to TDT tank (all sessions get text logs, but only these subjects get tank records)
* **trackFerrets**: List of subjects in which to use high res video (all other subjects will be videoed with the split_screen video)
* **order**: Optional, dictionary used to provide metadata to users on the order in which to run ferrets
