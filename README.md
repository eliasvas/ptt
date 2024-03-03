# ssg
This should (💀) become a game at some point. Its still pretty early for details though.
## description
Jai proof-of-concept game made *from scratch*. <br />
Main goal is to have a tiny (**<10 MB**) game to show. <br />
## state
![](https://progress-bar.dev/20/?title=rendering) <br />
![](https://progress-bar.dev/45/?title=mathLib) <br />
![](https://progress-bar.dev/0/?title=actualGame) <br />
![](https://progress-bar.dev/25/?title=gui) <br />
## build + run
You need to have a Jai compiler, git, git-lfs installed along with an OpenGL 3.3 compatible GPU
```
apt-get install git
apt-get install git-lfs
cd ssg && jai -quiet build.jai && ./.build/ssg
```