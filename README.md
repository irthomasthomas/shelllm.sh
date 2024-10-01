# Prompt Improvement and Shell Automation Tools

## Project Description

This repository contains a collection of shell scripts and utilities that enhance user prompts, explain shell commands, generate shell scripts, and provide a mindstorm of ideas based on user input. These tools leverage large language models (LLMs) to provide intelligent and customizable assistance for various shell-related tasks.

## Installation

To use these tools, you'll need to have the following installed:

1. A shell environment (e.g., Bash, Zsh)
2. The `llm` command-line tool, which provides an interface to the language model. You can install it using pip:

   ```
   pip install llm
   ```

3. The scripts included in this repository. You can clone the repository and add the scripts to your system's `PATH` environment variable.

## Usage

### `prompt-improver`
The `prompt-improver` script takes a user prompt as input and enhances it with additional information based on the requested response verbosity level. This can be useful for generating more detailed or verbose responses from language models.

Usage:
```
prompt-improver [-v <verbosity>] "<user_prompt>"
```

### `shell-explain`
The `shell-explain` script takes a shell command as input and provides an explanation of the command's functionality, with the level of detail controlled by the verbosity level.

Usage:
```
shell-explain [<verbosity>] "<shell_command>"
```

### `shell-commander`
The `shell-commander` script, aliased as `shelp`, generates a shell command based on a user prompt. It uses the language model to understand the user's intent and provide a relevant shell command.

Usage:
```
shell-commander "<user_prompt>"
```

### `shell-scripter`
The `shell-scripter` script generates a complete bash shell script based on a user prompt. It provides the reasoning, explanation, and the generated script code.

Usage:
```
shell-scripter "<user_prompt>"
```

### `mindstorm-generator`
The `mindstorm-generator` script generates a "mindstorm" of ideas based on a user prompt. The level of creativity and divergence of the ideas can be adjusted by specifying a different language model.

Usage:
```
mindstorm-generator [-m <model>] "<user_prompt>"
```

### `py-explain`
The `py-explain` script takes a Python code snippet as input and provides an explanation of the code, with the level of detail controlled by the verbosity level.

Usage:
```
py-explain [<verbosity>] "<python_code>"
```

## Contributing

If you would like to contribute to this project, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Make your changes and test them thoroughly.
4. Submit a pull request with a detailed description of your changes.

We welcome contributions that improve the functionality, documentation, or user experience of these tools.