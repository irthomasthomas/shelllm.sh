# AI-Powered Shell Toolkit

## Project Description
The AI-Powered Shell Toolkit is a collection of shell scripts that leverage large language models (LLMs) to enhance the user's shell experience. These scripts provide various functionalities, including improving command prompts, explaining shell commands, generating shell scripts, and more.

## Installation
To use the AI-Powered Shell Toolkit, you will need to have the following dependencies installed:
- A recent version of Bash or a compatible shell
- The `llm` command-line tool (https://github.com/anthropic-research/llm)

Once you have the dependencies installed, you can download the shell scripts from the repository and add them to your system's `PATH` environment variable.

## Usage

### `prompt-improver`
The `prompt-improver` script takes a user prompt and enhances it with additional information based on the requested verbosity level. This can be useful for providing more context or instructions to the user.

Usage:
```
prompt-improver [-v <verbosity>] "<user_prompt>"
```

### `shell-explain`
The `shell-explain` script provides an explanation of a shell command, with the level of detail controlled by the verbosity parameter.

Usage:
```
shell-explain [<verbosity>] "<shell_command>"
```

### `shell-commander`
The `shell-commander` script takes a shell command and generates the corresponding reasoning and command for the user.

Usage:
```
shelp "<shell_command>"
```

### `shell-scripter`
The `shell-scripter` script generates a shell script based on a user prompt, along with an explanation of the script's purpose.

Usage:
```
shell-scripter "<user_prompt>"
```

### `mindstorm-generator`
The `mindstorm-generator` script generates a "mindstorm" of ideas based on a user prompt, using a specified language model.

Usage:
```
mindstorm-generator [-m <model>] "<user_prompt>"
```

### `py-explain`
The `py-explain` script provides an explanation of a Python code snippet, with the level of detail controlled by the verbosity parameter.

Usage:
```
py-explain [<verbosity>] "<python_code>"
```

## Contributing
Contributions to the AI-Powered Shell Toolkit are welcome! If you have any ideas for new features, bug fixes, or improvements, please feel free to submit a pull request. Make sure to follow the project's coding conventions and provide clear documentation for any changes.