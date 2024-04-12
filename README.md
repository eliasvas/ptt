# ptt
A Pokemon Type-Trainer game to learn how types work in pokemon games.
## description
Jai proof-of-concept simple game made *from scratch*. <br />
Main goal is to have a tiny (**<10 MB**) game to show. <br />
## state
![](https://progress-bar.dev/35/?title=rendering) <br />
![](https://progress-bar.dev/60/?title=mathLib) <br />
![](https://progress-bar.dev/40/?title=actualGame) <br />
![](https://progress-bar.dev/75/?title=gui) <br />
## build + run
You need to have a Jai compiler, git, git-lfs, SDL2 installed along with an OpenGL 3.3 compatible GPU
```console
apt-get install git git-lfs libsdl2-dev libsdl2-2.0-0 -y
git clone https://github.com/eliasvas/ptt
cd ptt/ && jai -quiet build.jai && ./.build/ptt
```