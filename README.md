# Classifying EEG freewill Pre-Movement Intentions Using Q-learning-based Neural Decoders in Reinforcement Learning Brain Machine Interfaces

## Python files

- `main_all.py`: Main experiment. Loads the EEG dataset, applies band-pass settings, then,  train a deep Q-learning based decoder to classify premovement intention  and saves per-subject/section success-rate curves.
- `models.py`: Neural network architectures and reinforcement-learning components used by the decoder, including the CNN+LSTM EEG classifier, an EEGNet implementation, a replay buffer, and a DQNAgent wrapper that handles action selection and network updates.
- `utils.py`:  Utilities for the DQN EEG decoder, including target geometry helpers (reaching_target_xy), cursor/target step logic, per-channel standardization, the main training loop (with early stopping), and success-rate plotting.
- `data_function.py`: Core EEG data utilities and preprocessing helpers (e.g., raw feature extraction and anti-aliased downsampling via Butterworth low-pass filtering + cubic-spline resampling). 
- `load_data.py`: Loader for the Freewill Reaching & Grasping `.mat` files. Walks the dataset directory, parses subject/session filenames, and returns a nested dict of loaded MATLAB structures.


## Dataset

This project uses the [Freewill Reaching & Grasping EEG dataset](https://figshare.com/articles/dataset/A_Large_Electroencephalogram_Database_of_Freewill_Reaching_and_Grasping_Tasks_for_Brain_Machine_Interfaces/28632599?file=57518986).  
For instructions on **downloading** the data and a walkthrough of the dataset’s **folder/file structure**, along with **Python scripts** to load and preprocess it, see the companion tutorial repository:  
[EEG_Freewill_reaching_grasping_load_data](https://github.com/sposso/EEG_Freewill_reaching_grasping_load_data)
