# Shell Scripts

## Project Description
This repository contains a collection of shell scripts that provide various functionalities to assist with task planning, shell command execution, and code generation. These scripts utilize the capabilities of a large language model (LLM) to enhance the user experience and provide intelligent responses.

## Shell Scripts

### `shelllm.sh`
- **Description:** This script provides a `shell-commander` function that allows you to execute shell commands and receive a response with optional verbosity. It also includes a `task_planner` function for generating task plans, and a `shell-explain` function for explaining shell commands.
- **Usage:**
  - `shelp "ls -la"`: Execute the `ls -la` command and receive the response.
  - `task_plan "organize files in ~/Documents"`: Generate a task plan for organizing files in the `~/Documents` directory.
  - `explainer "echo 'Hello, World!'"`: Receive an explanation for the `echo 'Hello, World!'` command.

### `shell-scripter.sh`
- **Description:** This script provides a `shell-scripter` function that generates shell scripts based on user input and provides explanations for the generated scripts.
- **Usage:**
  - `scripter "Create a script that backs up my files to an external drive"`: Receive a generated shell script that backs up files to an external drive, along with an explanation.

### `prompt-improver.sh`
- **Description:** This script provides a `prompt-improver` function that generates an improved prompt based on user input.
- **Usage:**
  - `prompt-improver "write a short story about a day in the life of a robot"`: Receive an improved prompt for writing a short story about a robot.

### `mindstorm-ideas-generator.sh`
- **Description:** This script provides a `mindstorm-ideas-generator` function that generates creative ideas based on user input.
- **Usage:**
  - `mindstorm "build a robot that can clean my house"`: Receive a set of creative ideas for building a robot that can clean a house.

### `py-explain.sh`
- **Description:** This script provides a `py-explain` function that explains Python code with optional verbosity.
- **Usage:**
  - `py-explain 3 "print('Hello, World!')"`: Receive a detailed explanation of the `print('Hello, World!')` Python code with a verbosity level of 3.

### `digraph-generator.sh`
- **Description:** This script provides a `digraph-generator` function that generates a digraph based on user input with optional verbosity.
- **Usage:**
  - `digraph "create a diagram of the relationships between various software components"`: Receive a generated digraph diagram that represents the relationships between software components.

### `search-term-engineer.sh`
- **Description:** This script provides a `search-term-engineer` function that generates high-quality search queries based on user input with optional verbosity.
- **Usage:**
  - `search-term 3 "best practices for building a web application"`: Receive three high-quality search queries related to best practices for building a web application.

### `write-agent-plan.sh`
- **Description:** This script provides a `write-agent-plan` function that generates an agent plan based on a task description with optional verbosity.
- **Usage:**
  - `agent_plan "write a report summarizing the key findings from a market research study"`: Receive an agent plan with 5 steps for writing a report summarizing market research findings.

### `analytical-hierarchy-process-agent.sh`
- **Description:** This script provides an `analytical-hierarchy-process-agent` function that generates an Analytical Hierarchy Process (AHP) analysis based on user-provided ideas, criteria, and weights.
- **Usage:**
  - `ahp ideas criterion weights`: Receive an AHP analysis for the provided ideas, criteria, and weights.

### `commit-msg-generator.sh`
- **Description:** This script provides a `commit-msg-generator` function that generates Git commit messages based on the staged changes in the repository.
- **Usage:**
  - `commit_msg`: Stage all changes, generate a commit message, and push the changes to the remote repository.

### `cli-ergonomics-agent.sh`
- **Description:** This script provides a `cli-ergonomics-agent` function that analyzes the ergonomics of a command-line interface and suggests improvements.
- **Usage:**
  - `cli_ergonomics_agent "--n=Improve the CLI for the file management tool" "file-manager --help"`: Receive a refactored command-line interface with improved ergonomics for the `file-manager --help` command.

## Installation
1. Clone the repository: `git clone https://github.com/your-username/your-repo.git`
2. Source the shell scripts in your shell configuration file (e.g., `.bashrc`, `.zshrc`):
   ```
   source /path/to/repository/shelllm.sh
   source /path/to/repository/shell-scripter.sh
   # Source other scripts as needed
   ```

## Usage
Refer to the individual script descriptions above for information on how to use each functionality.

## Contributing
If you would like to contribute to this project, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Make your changes and test them thoroughly.
4. Submit a pull request with a detailed description of your changes.

We welcome contributions that improve the functionality, usability, or documentation of the shell scripts in this repository.