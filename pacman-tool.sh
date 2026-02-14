#!/bin/sh
lockfile()
{
    sudo -s echo "";
    lockfile_deleted=0
    if [[ -f /var/lib/pacman/db.lck ]]; then
        sudo rm -rf /var/lib/pacman/db.lck
        lockfile_deleted=1
    else
        if [[ -d /var/lib/pacman ]]; then
            echo -e "Default directory detected, but no db.lck file found. \nIf the issue still occurs, look on your distro's forums for similar issues! It may be fixed by an update or something similar."
            exit 0
        else
            while :; do
                echo "/var/lib/pacman/ does not exist! Is pacman in a nonstandard dir? [Y/n]"
                read in_ns;
                if [[ "$in_ns" == "" || "$in_ns" == "y" || "$in_ns" == "Y" ]]; then
                    echo "What directory are the pacman library files in, then?"
                    read dir_answer;
                    if ! [[ -d dir_answer ]]; then
                        echo "That directory does not exist, try again."
                    else
                        echo "Directory exists, attempting lock file deletion..."
                        if [[ -f "$dir_answer/db.lck" ]]; then
                            sudo rm -rf "$dir_answer/db.lck"
                            if ! [[ -f /var/lib/pacman/db.lck ]]; then
                                lockfile_deleted=1
                            fi
                        else
                            echo "db.lck does not exist in given directory, $dir_answer"
                        fi
                        break
                    fi
                fi
            done
        fi
    fi
    if [[ "$lockfile_deleted" == 1 ]]; then
        if ! [[ -f /var/lib/pacman/db.lck || -f "$dir_answer/db.lck" ]]; then
            echo "Lockfile was deleted successfully! Do you want to test Pacman? [Y/n]"
            read test_answer;
            if [[ "$test_answer" == "" || "$test_answer" == "y" || "$test_answer" == "Y" ]]; then
                echo "Okay! Testing pacman... (this might take a while!)"
                pacman_logs=$(sudo pacman -Syu 2>&1)
                if ! [[ "$pacman_logs" == *"error: failed to synchronize all databases (unable to lock database)"* ]]; then
                    echo "Seems like your issue has been fixed (Hopefully)! Have fun!"
                    exit 0
                else
                    echo "Uh-oh... It didn't work! This might be a distro-dependent issue, so I can't help from here... Sorry! :("
                    exit 2
                fi
            fi
        else
            echo "FUCK"
        fi
    fi
}
reset_key()
{
    echo "Trying to delete current keyring..."
    if [[ -d /etc/pacman.d/gnupg ]]; then
        sudo rm -rf /etc/pacman.d/gnupg
        echo "Keys deleted. Refreshing keys..."
    else
        echo "Keyring not found. Are keys in a nonstandard dir? [Y/n]"
        read in_ns;
        if [[ "$in_ns" == "" || "$in_ns" == "y" || "$in_ns" == "Y" ]]; then
            echo "Where are they, then?"
            read key_dir;
            if [[ -d "$key_dir" ]]; then
                sudo rm -rf /etc/pacman.d/gnupg
                echo "Keys deleted. Refreshing keys..."
            else
                echo "Keys not found in directory. Do you want to try to refresh keyring anyway? [y/N]"
                read refresh_answer;
                if ! [[ "$refresh_answer" == "y" || "$refresh_answer" == "Y" ]]; then
                    exit 0
                fi
            fi
        fi
    fi
    id=$(grep -A 1 "ID=" /etc/os-release | tail -n +2)
    sudo pacman-key --init > /dev/null
    sudo pacman-key --populate archlinux $id >/dev/null 2>&1
    sudo pacman-key --populate > /dev/null
    echo "Keys refreshed. Do you want to try to test Pacman?"
    read test_answer;
    if [[ "$test_answer" == "" || "$test_answer" == "y" || "$test_answer" == "Y" ]]; then
        echo "Okay! Testing pacman... (this might take a while!)"
        pacman_logs=$(sudo pacman -Syu 2>&1)
        if ! [[ "$pacman_logs" == *"package (PGP signature)"* ]]; then
            echo "Seems like your issue has been fixed (Hopefully)! Have fun!"
            exit 0
        else
            echo "Uh-oh... It didn't work! This might be a distro-dependent issue, so I can't help from here... Sorry! :("
            exit 2
        fi
    fi
}

echo "Select problem:"
echo -e "[1] Unable to lock database \n[2] Corrupted key"
read answer;
if [[ "$answer" == "1" ]]; then
    lockfile
fi

if [[ "$answer" == "2" ]]; then
    reset_key
fi

if [[ "$answer" != "1" && "$answer" != "2" ]]; then
    exit 1
fi
