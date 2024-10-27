# Project Name

## Project Description

This project consists of a collection of shell scripts that provide various functionality to the user. The scripts cover a range of tasks, including code explanation, shell command execution, task planning, bash script generation, prompt improvement, and more. These scripts are designed to enhance the user's productivity and streamline their workflow.

## Installation

To use the scripts in this repository, you will need to have the following dependencies installed:

- Bash shell
- [llm](https://github.com/anthropic-research/llm) (Language Model Command-Line Interface)

Once you have the dependencies installed, you can clone the repository and add the scripts to your system's `PATH` variable for easy access.

## Usage

The repository contains the following shell scripts:

### `auxiliary_functions.sh`
This file contains various auxiliary functions used by the other scripts in the repository.

### `shelllm.sh`
This file contains the following functions:

- `write-agent-plan`: Writes an agent plan with a specified verbosity level.
- `code-explainer`: Explains the given code with optional reasoning and verbosity control.
- `shell-commander`: Executes a shell command with optional reasoning and verbosity control.
- `task-planner`: Generates a task plan with optional reasoning and verbosity control.
- `bash-script-generator`: Generates a Bash script with optional reasoning and verbosity control.
- `prompt-improver`: Improves the given prompt with optional reasoning and verbosity control.
- `mindstorm-ideas-generator`: Generates creative ideas based on the provided input.
- `digraph-generator`: Generates a digraph (directed graph) with optional reasoning and verbosity control.
- `search-term-engineer`: Generates search terms with optional reasoning and verbosity control.
- `ai-judge`: Classifies the given code samples and determines the better candidate.
- `analytical-hierarchy-process-generator`: Generates an Analytical Hierarchy Process (AHP) analysis with optional verbosity and notes.
- `commit-msg-generator`: Generates a commit message based on the current Git diff and pushes the changes to the remote repository.
- `cli-ergonomics-engineer`: Refactors the provided command-line interface (CLI) to improve its ergonomics.

To use these functions, you can either source the `shelllm.sh` file in your shell or use the provided aliases.

## Contributing

If you'd like to contribute to this project, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Implement your changes and test them thoroughly.
4. Update the README.md file with any necessary information about your changes.
5. Submit a pull request.

We welcome contributions that improve the functionality, efficiency, or usability of the scripts in this repository.