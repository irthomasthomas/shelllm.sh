# Prompt Engineering Utilities

## Project Description
This repository contains a collection of shell scripts and Python utilities designed to enhance the user experience and productivity in working with large language models (LLMs) for various tasks. These scripts provide functionality for improving command line prompts, explaining shell commands, generating shell scripts, and stimulating idea generation through mindstorming.

## Installation
To use the utilities in this repository, you'll need to have the following software installed on your system:

- Python (version 3.6 or later)
- A large language model (LLM) like GPT-3 or similar, accessible through a command-line interface

Once you have these dependencies, you can clone the repository and add the scripts to your system's PATH or use them directly from the cloned directory.

## Usage

### Shell Scripts

#### `prompt-improver`
The `prompt-improver` script helps to improve a user's command line prompt by incorporating additional information and verbosity based on the user's request. It takes a user prompt as input and generates an enhanced prompt with the requested level of verbosity.

Usage:
```
prompt-improver [-v <verbosity>] <user_prompt>
```

#### `shell-explain`
The `shell-explain` script provides explanations for shell commands, with the level of detail controlled by the user's requested verbosity. It takes a shell command as input and generates a short explanation of the command's functionality.

Usage:
```
shell-explain [<verbosity>] <shell_command>
```

#### `shell-commander`
The `shell-commander` script generates shell commands based on a user's request, along with an explanation of the reasoning behind the generated command. It takes a user prompt as input and outputs the corresponding shell command.

Usage:
```
shell-commander <user_prompt>
```

Alias: `shelp`

#### `shell-scripter`
The `shell-scripter` script generates shell scripts based on a user's request, along with an explanation of the script's purpose and functionality. It takes a user prompt as input and outputs the generated shell script.

Usage:
```
shell-scripter <user_prompt>
```

#### `mindstorm-generator`
The `mindstorm-generator` script generates a mindstorm of ideas based on a user's prompt. It takes a user prompt as input and generates a list of related ideas using a specified LLM model.

Usage:
```
mindstorm-generator [-m <model>] <user_prompt>
```

### Python Scripts

#### `py-explain`
The `py-explain` script provides explanations for Python code, with the level of detail controlled by the user's requested verbosity. It takes Python code as input and generates a detailed explanation of the code's functionality.

Usage:
```
py-explain [<verbosity>] <python_code>
```

## Contributing
If you would like to contribute to this project, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Implement your changes and write any necessary documentation.
4. Test your changes to ensure they work as expected.
5. Submit a pull request with a detailed description of your changes.

We welcome contributions from the community to help improve and expand the functionality of these utilities.