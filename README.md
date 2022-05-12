# GoFerret

Matlab framework for behavioral testing.

## Requirements
- Matlab (tested on every version since R2011)
- OpenEx Developer Tools ([Tucker Davis Technologies](https://www.tdt.com/support/downloads/))
- Python (optional, for video recording with Realsense cameras)

<br>


## Get Started

Download the repository and update paths / settings in config.json (see [Set Configuration](docs/set_config.md) for more details)

Open repository as the current folder in in Matlab, or add to Matlab path, and run the following in the command line:


```sh
GoFerret
```

<img src="docs/GoFerret_screenshot.png" alt="Screenshot of main GUI" style="width:900px;height:522px;">




## Tasks

### Vowel discrimination
Used to study [perceptual constancy](https://www.nature.com/articles/s41467-018-07237-3), [vowel discrimination in noise](https://www.biorxiv.org/content/10.1101/833558v1) and [formant weighting](https://asa.scitation.org/doi/10.1121/1.4916690)

### Approach-to-target sound localization
Task for testing [effects of cortical inactivation on spatial hearing](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0170264)

### Coordinate specific sound localization
Used to study whether listeners can report the location of sounds in [world or head-centered space](https://www.jneurosci.org/content/early/2022/04/27/JNEUROSCI.0291-22.2022.abstract).

### Measuring frequency-response areas
Presentation of tones with varying intensities and frequencies, used to characterize the spectral tuning of neurons and map tonotopy across neural populations.
  
