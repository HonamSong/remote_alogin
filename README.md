
# remote_alogin
 telnet/ssh server auto login script


## Install 
```
git clone https://github.com/HonamSong/remote_alogin.git
cd remote_alogin
chmod +x r_conn.sh
```

## Run
```
cd {git_path}
./r_conn.sh
```

## Setting Alias 
> bash
```
echo "alias r_conn='/bin/bash {$GIT_CLONE_PATH}/r_conn.sh'" >> ~/.bashrc
source ~/.bashrc
``` 
> zsh
```
echo "alias r_conn='/bin/bash /app/test/remote_alogin/r_conn.sh'" >> ~/.zshrc
source ~/.zshrc
``` 


## Help

```
[ user_name@hostname ] # r_conn --help

   ____  _   _ _____ _     ____   ____
  / / / | | | | ____| |   |  _ \  \ \ \
 / / /  | |_| |  _| | |   | |_) |  \ \ \
 \ \ \  |  _  | |___| |___|  __/   / / /
  \_\_\ |_| |_|_____|_____|_|     /_/_/

  + Version :  0.0.3


usage) /app/test/remote_alogin/r_conn.sh [options]

==================================================

  [ Option ]

    -h, --help     	Help
    --is_debug     	Debug mode
    --is_showlog   	print the log
    --is_showsend  	print connect command
[ user_name@hostname ] #
```


