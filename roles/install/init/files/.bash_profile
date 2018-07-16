# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin

export PATH
export PS1="[\[\e[36;1m\]\u@\[\e[32;1m\]\H \[\e[35;1m\]\W\[\e[0m\]]\\$ "
