LLM Pipeline pattern
=================
Example: search_terms_generator | web_searcher | prompt_engineer
For this to work, search_terms_generator and web_searcher should ouput the original input prompt and pass it along.
Then prompt_engineer would have access to the original user prompt, the search terms, and the web search results.


File Watch
Have file_watch watch for IDEAS.md and TODO.md - then pass the changes to the LLM conversation.
Optionally, when an agent is running, the watch on the active project should be paused.
When the agent is stopped, the watcher should be resumed.

There may be a pattern where monitoring the TODO.md and IDEAS.md of the active agent session is useful. For having an overview activity.


# Glossary
Implement an llm driven glossary to keep track of new terms and definitions discovered during the conversation.
Some rough ideas to discuss:
drafts/glossary.md contains some draft implementations to be adapted to specific LLM library usage.


# Token efficiency expert prompt
Analyze scripts used by llm agents and look for dangerous patterns and inefficiencies.
Pay special attention code that reads from files, or uses the filesystem, or untrusted input, network, etc. Suggest ways limit the risk of too many tokens being used from running the code.