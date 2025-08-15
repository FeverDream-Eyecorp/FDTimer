# FDTimer
A simple TUI timer for Rubik's Cubes. I doubt anyone is going to use this but I'm uploading it just in case.

# Why?
I just thought it'd be cool to have a TUI timer I could use for timing my speed solves. From my reserch, (at most 10 minutes of Googling) there aren't really any good, functional timers that run in the console. I did find (this)[https://github.com/paarthmadan/cube], but it does appear to be a kind of abandoned project. Either that or the creator has a real big update in the works.

# I think I know what I'm doing
This is my first time using GitHub aside from to download stuff. I don't even usually do version control on my code, so bare with me. I have done a lot of reading other people's stuff though so I have a general idea.

# Requirements
- A standard installation of Perl 5 with the following installed:
  - Term::ReadKey
  - JSON

# Usage
You can run `perl FDTimer.pl --help` for this same help thing.

The script will look for an `FDTimer.json` in its own path, and help create a new one if that's not present. Once you start using the script, this is where your times & categories will be stored. Once the file is there, running the script will bring you to the main interface.
