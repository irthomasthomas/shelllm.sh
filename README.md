# Shell Scripts for AI-Powered Workflow Automation

## Project Description

This repository contains a collection of shell scripts that leverage large language models (LLMs) to automate various tasks and workflows. These scripts provide a user-friendly interface to interact with the LLMs and perform a wide range of operations, including:

- Generating and explaining code snippets
- Producing task plans and bash scripts
- Improving existing prompts
- Generating search terms and conducting analytical hierarchy processes
- Automatically generating and pushing commit messages to a Git repository
- Optimizing command-line interfaces for better ergonomics

The scripts are designed to enhance productivity, streamline development processes, and leverage the capabilities of LLMs to augment human intelligence.

## Installation

To use the scripts in this repository, you will need the following:

1. A working installation of the `llm` command-line tool, which provides the interface to interact with the LLMs. You can find instructions for installing the `llm` tool [here](https://github.com/Anthropic/llm).
2. The shell scripts from this repository, which can be downloaded or cloned from the GitHub repository.

Once you have the necessary components, you can start using the scripts by sourcing the relevant files in your shell environment.

## Usage

The repository contains the following shell scripts and their corresponding use cases:

### Shell Scripts

#### `shelp_gemini.sh`
This script provides a user-friendly interface to interact with the Gemini language model. It allows you to generate and execute shell commands based on user input and supports various options, such as setting the reasoning length and verbosity level.

#### `shelllm.sh`
The `shelllm.sh` script includes two main functions:
1. `write-agent-plan`: Generates a task plan for an agent based on user input.
2. `code_explainer`: Provides an explanation for a given code snippet, with the option to display the reasoning process.

#### `auxiliary_functions.sh`
This file contains auxiliary functions used by the other shell scripts in the repository.

### Python Scripts

There are no Python scripts in the provided repository content.

### Terraform Files

There are no Terraform files in the provided repository content.

### Usage Examples

Here are some example commands to use the provided shell scripts:

```bash
# Generate a shell command using the Gemini language model
shelp_gemini --reasoning=5 --model=claude-3.5-sonnet "Write a Bash script to automate a backup process."

# Explain a code snippet
code_explainer --reasoning=3 --show-reasoning "def factorial(n):\n    if n == 0:\n        return 1\n    else:\n        return n * factorial(n-1)"

# Generate a task plan
write-agent-plan "Implement a new feature for the web application."

# Generate a commit message and push to a Git repository
commit-msg-generator -v=7 -n="Refactor the login functionality"

# Optimize a command-line interface
cli-ergonomics-engineer --v=5 "My CLI Tool" 
```

## Contributing

If you would like to contribute to this project, please follow these guidelines:

1. Fork the repository and create a new branch for your changes.
2. Implement your improvements or bug fixes in the appropriate shell scripts.
3. Test your changes thoroughly and ensure they do not break existing functionality.
4. Update the README.md file to document any new features or changes.
5. Submit a pull request with a clear description of your changes and the problems they address.

Your contributions are greatly appreciated, as they help make this project more robust and useful for the community.