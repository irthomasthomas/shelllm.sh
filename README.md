# Shelp: An AI-Powered Shell Scripting Assistant

## Project Description

Shelp is a shell script repository that leverages large language models (LLMs) to enhance the shell scripting experience. The project includes a set of shell scripts that utilize the LLM to perform various tasks, such as generating shell commands, explaining code, creating task plans, and more. The goal of Shelp is to provide developers with a powerful tool that can help them automate and streamline their shell scripting workflows.

## Installation

To use Shelp, you will need to have the following installed:

- A compatible shell (e.g., Bash, Zsh)
- A large language model (e.g., GPT-3, GPT-4)

To install the Shelp scripts, follow these steps:

1. Clone the Shelp repository:

```
git clone https://github.com/your-username/shelp.git
```

2. Source the `shelllm.sh` file in your shell configuration file (e.g., `.bashrc`, `.zshrc`):

```
source /path/to/shelp/shelllm.sh
```

3. (Optional) Install any additional dependencies required by the shell scripts.

## Usage

Shelp provides a variety of shell scripts that you can use to enhance your shell scripting experience. Here's a brief overview of the available scripts:

### `shelp_gemini.sh`
This script provides a shell-based interface to interact with an LLM. It supports various options, such as setting the prompt, reasoning length, and verbosity level. The script generates shell commands based on the user's input and prompts.

Usage:
```
shelllm_gemini --prompt="<PROMPT>" --reasoning=<REASONING_LENGTH> --verbosity=<VERBOSITY_SCORE> [other options]
```

### `auxiliary_functions.sh`
This file contains additional helper functions that can be used in conjunction with the other Shelp scripts.

### `shelllm.sh`
This file contains the core functionality of the Shelp project, including functions for generating shell commands, explaining code, creating task plans, and more. The file is still in flux, and some functions may not conform to the same format or behavior.

### `ai-judge.sh`
This script is used to compare and evaluate code snippets provided by different candidates. It takes the original code and the candidate's refactored code as input, and uses an LLM to determine which code is better.

Usage:
```
ai-judge "original_code" "candidate_one" "candidate_two" -c "candidate_one" "candidate_two" --no-content -m gpt-4
```

### Other Scripts
The repository may contain additional shell scripts that provide various functionalities, such as generating commit messages, refactoring CLI interfaces, and more. Each script will have its own usage instructions and descriptions.

## Contributing

Contributions to the Shelp project are welcome. If you have any ideas, bug fixes, or new features you'd like to add, please follow these steps:

1. Fork the repository.
2. Create a new branch for your changes.
3. Make your changes and ensure they work as expected.
4. Submit a pull request with a detailed description of your changes.

Please make sure to follow the existing code style and conventions when contributing.