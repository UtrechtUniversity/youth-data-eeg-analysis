# 🧠 EEG Connectivity Analysis Pipeline (YOUth)

This pipeline is meant for preprocessing and running a network connectivity
analysis on data from the YOUth Cohort study (Onland-Moret et al., 2020)[^1].
It is specifically suited to reproduce the connectivity analysis of
van der Velde et al. (2021)[^2], investigating the emergence of a theta social
brain network during infancy, in the context of COVID-19 related policy effects.

## 📦 Requirements

- MATLAB (the pipeline was tested on version R2025b)
- the following toolboxes:
  - Image Processing Toolbox
  - Optimization Toolbox
  - Signal Processing Toolbox
  - Statistics and Machine Learning Toolbox
- Small World Propensity function[^3] (included)
- Fieldtrip (tested on revision fcee93fc2, included with the pipeline)
- Network Community Toolbox[^4] (included in FieldTrip)
- YOUth Data

> [!NOTE]
> You can follow the instructions [here](https://nl.mathworks.com/help/install/ug/install-products-with-internet-connection.html) for installing MATLAB and the toolboxes.
> You can find instructions for installing Fieldtrip [here](https://www.fieldtriptoolbox.org/download/)
> if you want to download it yourself.
> You can request YOUth Data following [this](https://www.uu.nl/en/research/youth-cohort-study/request-youth-data) link.

## 🚀 Getting Started

To get started, simply download (or clone) this GitHub repository and unzip to a folder on your device, where you can find it later.

> [!TIP]
> You can clone the repository by following [this](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository?platform=windows) guide.

## 🔨 Usage

1. Make sure that you **always** start in the pipeline directory.
2. Place the YOUth datafiles in the RAW folder. Preserve the provided folder structure.
3. Start MATLAB (from the pipeline directory) and open *main_script.m*
4. Run the code section-by-section. Pay attention to any comments and adjust the code to your liking.

> [!WARNING]
> It is crucial that you run the code section-by-section, and not all at once.
> Otherwise, MATLAB will run into errors.

> [!WARNING]
> The pipeline reproduces the original work that analysed RAW files from 
> the 5-months and 10-months old waves of the YOUth Cohort.
> Putting any other RAW files in the RAW folder might
> cause the pipeline to run into an error.
> (However, the pipeline was successfully tested with data from the 3-years and
> 6-years old waves.)

## 📄 License

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

This project is licensed under the GNU General Public License v3.0 — see the [LICENSE](LICENSE) file for details.

[^1]: Onland-Moret, N. C., Buizer-Voskamp, J. E., Albers, M. E., Brouwer, R. M., Buimer, E. E., Hessels, R. S., De Heus, R., Huijding, J., Junge, C. M., Mandl, R. C., Pas, P., Vink, M., Van Der Wal, J. J., Pol, H. E. H., & Kemner, C. (2020). The YOUth study: Rationale, design, and study procedures. Developmental Cognitive Neuroscience, 46, 100868. <https://doi.org/10.1016/j.dcn.2020.100868>

[^2]: Van der Velde, B., White, T., & Kemner, C. (2021). The emergence of a theta social brain network during infancy. NeuroImage, 240, 118298. <https://doi.org/10.1016/j.neuroimage.2021.118298>

[^3]: Muldoon, S. F., Bridgeford, E. W., & Bassett, D. S. (2015) Small-World Propensity in Weighted, Real-World Networks. Neurons and Cognition. <https://doi.org/10.48550/arXiv.1505.02194> 

[^4]: Network Community Toolbox. (n.d.). [Computer software]. <http://commdetect.weebly.com/>
