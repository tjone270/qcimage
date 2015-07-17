## Repo Functions

function repo_init {
    mount_windows
    cd $WINDOWS_DIR
    if [ -e .git ]; then
	/bin/rm -rf .git
	/bin/rm -rf ${LOCAL_LINUX_TEMPLATE}$REPO_DIR
    fi
    git init .
    cp -u /qcimage/windows_root/.gitignore .
    mv .git ${LOCAL_LINUX_TEMPLATE}$REPO_DIR
    echo "gitdir: ${LOCAL_LINUX_TEMPLATE}$REPO_DIR" > .git
    git add .
    git commit -m "Initial import"
    echo "gitdir: $REPO_DIR" > .git
}

function repo_update {
    cd $WINDOWS_DIR
    git add .
    git commit -m"update"
}

function repo_reset {
    cd $WINDOWS_DIR
    plymouth display-message --text="Copying out the demos"
    sync_demos
    if [ -e $WINDOWS_DIR/.qcimage/reset ]; then
	rm $WINDOWS_DIR/.qcimage/reset
    fi
    plymouth display-message --text="Resetting to HEAD"
    git reset --hard
    plymouth display-message --text="Removing untracked files"
    git clean -f
    /bin/rm -rf $WINDOWS_DIR/.qcimage
    mkdir $WINDOWS_DIR/.qcimage
}

## Diff Functions

function generate_diff {
    #plymouth message --text="Generating Player Differential"
    cd $WINDOWS_DIR
    git add .
    git commit -m "fake"
    git diff --binary HEAD^1 > $DIFF
    git reset HEAD^1
}

function apply_diff {
    #plymouth message --text="Applying Player Diff"
    cd $WINDOWS_DIR
    repo_reset
    git apply --reject $DIFF
}

# Misc Helper Functions

function reload {
   . /etc/profile.d/qcimage.sh
}

#function boot_windows {
#   grub2-reboot "Windows"
#   reboot
#   echo "Ready to reboot!"
#}

