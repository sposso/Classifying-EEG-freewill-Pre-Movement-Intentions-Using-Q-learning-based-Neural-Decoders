# Classifying EEG freewill Pre-Movement Intentions Using Q-learning-based Neural Decoders

## Repository Python files

- `main_all.py`: Main experiment/training entry point. Loads the EEG dataset, applies band-pass settings, then runs Monte Carlo DQN training/evaluation loops and saves per-subject/section success-rate curves.
- `models.py`: Neural network architectures and reinforcement-learning components used by the decoder, including the CNN+LSTM EEG classifier, an EEGNet implementation, a replay buffer, and a DQNAgent wrapper that handles action selection and network updates.
- `utils.py`:  Utilities for the DQN EEG decoder, including target geometry helpers, cursor/target step logic, per-channel standardization, the main training loop (with early stopping), and success-rate plotting.
- `data_function.py`: Core EEG data utilities and preprocessing helpers (e.g., raw feature extraction and anti-aliased downsampling via Butterworth low-pass filtering + cubic-spline resampling), plus dataset-related helpers used by the training script.
- `load_data.py`: Convenience loader for the Freewill Reaching & Grasping `.mat` files. Walks the dataset directory, parses subject/session filenames, and returns a nested dict of loaded MATLAB structures.
