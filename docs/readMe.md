# GoFerret Docs

---

## Initial GUI

When GoFerret starts, it uses the paths listed in the configuration file to provide a series of lists from which to select:
1. User project
2. Task level
3. Task parameters
4. Experimental subject

### Quick Access Buttons
Quick access buttons automatically populate selection boxes with frequently used settings. 

### Weight Records
GoFerret also provides tools for interacting with the database containing subject metadata. In our use case, this involves being able to add, remove and visualise subject weights, which are recorded before every session.

---

## Tasks

Users can add tasks to GoFerret to perform different experiments. Each task has four components:
* **online.m**: a task specific GUI that shows incoming task information (e.g. current trial parameters)
* **levels**: a directory containing scripts with the prefix level**.m
* **parameters**: a directory containing metadata used for testing with a specific level, and possibly a specific subject
* **toolbox**: a directory of matlab helper functions called by the system during data acquisition
* **tdt**: directory containing RPvdsEx circuits used in OpenProject (see TDT tutorial for more information)

Details about each user project can be found in [Tasks](./tasks.md)