# Shell Scripts

## Project Description

This repository contains a collection of shell scripts that leverage large language models (LLMs) to provide various functionalities, including:

- **shelp_gemini.sh**: A script that provides a shell-based interface to interact with an LLM, allowing users to execute shell commands and receive responses with optional reasoning and verbosity controls.
- **auxiliary_functions.sh**: A file containing additional helper functions for the shell scripts in this repository.
- **shelllm.sh**: A script that provides a set of functions for interacting with LLMs, including writing agent plans, explaining code, generating shell commands, and more.
- **cli-ergonomics-engineer.sh**: A script that uses an LLM to analyze and refactor existing command-line interfaces (CLIs) to improve their ergonomics and user-friendliness.
- **commit-msg-generator.sh**: A script that generates commit messages for Git repositories using an LLM, based on the changes staged for commit.
- **analytical-hierarchy-process-generator.sh**: A script that uses an LLM to generate Analytical Hierarchy Process (AHP) analyses for decision-making scenarios.
- **search-engineer.sh**: A script that uses an LLM to generate a list of relevant search terms based on a given prompt.
- **brainstorm-generator.sh**: A script that uses an LLM to generate brainstorming ideas based on a given prompt.
- **digraph-generator.sh**: A script that uses an LLM to generate directed graph (digraph) visualizations based on a given prompt.
- **prompt-improver.sh**: A script that uses an LLM to generate improved prompts based on a given prompt.
- **bash-generator.sh**: A script that uses an LLM to generate Bash scripts based on a given prompt.

These scripts are designed to enhance the functionality and efficiency of various tasks by leveraging the capabilities of large language models.

## Installation

To use the scripts in this repository, you will need to have the following software installed:

- A Unix-based operating system (e.g., Linux, macOS)
- [llm](https://github.com/Anthropic/llm) command-line tool (or another tool for interacting with LLMs)

You can install the `llm` tool by following the instructions in the [llm repository](https://github.com/Anthropic/llm).

Once you have the necessary software installed, you can clone this repository and source the relevant script files in your shell environment.

## Usage

Each script in this repository has its own set of usage instructions and options. You can find the specific usage details for each script by running the script with the `--help` or `-h` flag.

For example, to use the `shelp_gemini.sh` script, you can run the following command:

```
source /path/to/shelp_gemini.sh
gshelp --prompt="<PROMPT>
Explain the purpose of the Analytical Hierarchy Process (AHP) and how it can be used for decision-making.
</PROMPT>" --reasoning=5 --verbosity=7
```

This will execute the `shelp_gemini` function, which will prompt the LLM to provide an explanation of the Analytical Hierarchy Process with a reasoning depth of 5 and a verbosity level of 7.

## Contributing

If you would like to contribute to this project, please follow these guidelines:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Implement your changes and ensure they work as expected.
4. Update the documentation (this README.md file) to reflect your changes.
5. Submit a pull request with a detailed description of your changes.

We welcome contributions that enhance the functionality, usability, or documentation of the shell scripts in this repository.