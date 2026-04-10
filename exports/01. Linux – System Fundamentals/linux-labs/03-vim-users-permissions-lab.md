[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-boot-basics-files-lab.md) |
[Lab 02](./02-filters-sed-awk-lab.md) |
[Lab 03](./03-vim-users-permissions-lab.md) |
[Lab 04](./04-archive-packages-services-lab.md) |
[Lab 05](./05-networking-lab.md)

---

# Lab 03 — Vim, Users & Permissions

## The Situation

The webstore project is ready to go to a second developer. Before you hand it over you need to do two things: lock down the file system so nobody can access what they should not, and prove that the access control actually works.

Right now everything is owned by your user. The config file containing the database password is readable by anyone on the server. The logs directory lets anyone write to it. That is not acceptable on a shared server.

By the end of this lab the webstore directory tree has a dedicated service user, a team group, correctly set permissions on every file and directory, and verified access control — `dev-user` can read the config but cannot write to it, and the logs directory accepts writes from team members. This is the state Lab 04 inherits when it installs nginx and needs to write to the logs directory.

## What this lab covers

You will edit the webstore config file using vim without touching the mouse, create a dedicated system user for the webstore service, create a team group, assign correct ownership and permissions to the webstore directories, and verify that access control works as expected. Every command is typed from scratch.

## Prerequisites

- [Text Editor notes](../07-text-editor/README.md)
- [User & Group Management notes](../08-user-&-group-management/README.md)
- [File Ownership & Permissions notes](../09-file-ownership-&-permissions/README.md)
- Lab 01 completed — `~/webstore/` directory must exist

---

## Section 1 — Vim Survival Skills

**Goal:** open, navigate, edit, and save a file using vim without a mouse.

1. Open the webstore config in vim
```bash
vim ~/webstore/config/webstore.conf
```

2. You are in Normal mode. Navigate using:
```
j → down
k → up
h → left
l → right
w → jump forward one word
b → jump backward one word
```

3. Jump to the last line
```
G
```

4. Jump to the first line
```
gg
```

5. Jump directly to line 3
```
3G
```

6. Enter Insert mode and add a new line at the bottom
```
o
```
Type: `debug=false`
Press `Esc` to return to Normal mode.

7. Search for `api_port`
```
/api_port
```
Press `n` to find the next match.

8. Replace `8080` with `8081` on the current line only
```
:s/8080/8081/
```

9. Replace all occurrences of `webstore` with `ws` globally — preview what it would do
```
:%s/webstore/ws/g
```
Undo it immediately:
```
u
```

10. Save and quit
```
:wq
```

11. Verify the change saved
```bash
cat ~/webstore/config/webstore.conf
```

12. Open the file again and quit WITHOUT saving
```bash
vim ~/webstore/config/webstore.conf
```
Make a random edit, then:
```
:q!
```

---

## Section 2 — Create Users and Groups

**Goal:** create a dedicated webstore service user and a team group.

1. Create the webstore group
```bash
sudo groupadd webstore-team
```

2. Confirm the group exists
```bash
grep webstore-team /etc/group
```

3. Create a system user for the webstore service — no home directory, no login shell
```bash
sudo useradd --system --no-create-home --shell /bin/false webstore-svc
```

**Why `--shell /bin/false`:** this user runs the webstore service but can never log into the server interactively. If the account is compromised, an attacker cannot get a shell.

4. Confirm the user exists and note the shell
```bash
grep webstore-svc /etc/passwd
```

**What to observe:** `/bin/false` as the shell — this user cannot log in.

5. Create a regular developer user
```bash
sudo useradd -m -s /bin/bash dev-user
sudo passwd dev-user
```

6. Add dev-user to the webstore-team group — always use `-a` to append
```bash
sudo usermod -aG webstore-team dev-user
```

7. Confirm the group membership
```bash
groups dev-user
```

8. Also add www-data (the nginx user) to webstore-team so nginx can read webstore files
```bash
sudo usermod -aG webstore-team www-data
```

9. Confirm all members of the group
```bash
getent group webstore-team
```

---

## Section 3 — Ownership and Permissions

**Goal:** set correct ownership and permissions on every webstore directory and file.

1. Check current ownership before changing anything
```bash
ls -lh ~/webstore/
```

2. Change ownership of the entire webstore directory tree
```bash
sudo chown -R webstore-svc:webstore-team ~/webstore/
```

3. Confirm the change
```bash
ls -lh ~/webstore/
```

4. Set directory permissions — owner full access, group can enter and read, others nothing
```bash
sudo chmod -R 750 ~/webstore/
```

5. Confirm permissions
```bash
ls -lh ~/webstore/
```

6. The logs directory needs group write — nginx writes logs here as www-data
```bash
sudo chmod 770 ~/webstore/logs/
ls -lh ~/webstore/
```

7. Config files should be read-only for the group — never writable
```bash
sudo chmod 640 ~/webstore/config/webstore.conf
ls -lh ~/webstore/config/
```

**Why 640 not 644:** `644` lets everyone on the server read the config — including the database password. `640` restricts read access to the owner and group members only.

---

## Section 4 — Verify Access Control

**Goal:** prove permissions actually block or allow access as expected.

1. Try to read the config as the current user
```bash
cat ~/webstore/config/webstore.conf
```

2. Try to read as dev-user — who is in webstore-team
```bash
sudo -u dev-user cat ~/webstore/config/webstore.conf
```

**What to observe:** dev-user can read — group has `r` permission on the config file.

3. Try to write to the config as dev-user
```bash
sudo -u dev-user bash -c 'echo "test" >> ~/webstore/config/webstore.conf'
```

**What to observe:** `Permission denied` — group only has read on config files, not write.

4. Try to write to the logs directory as dev-user
```bash
sudo -u dev-user bash -c 'echo "192.168.1.99 GET /api/products 200 512" >> /home/$USER/webstore/logs/access.log'
```

**What to observe:** permitted — logs directory has `770` so group members can write.

---

## Section 5 — Special Permissions

**Goal:** apply SGID to the logs directory so new files always inherit the webstore-team group.

1. Set SGID on the logs directory
```bash
sudo chmod g+s ~/webstore/logs/
ls -ld ~/webstore/logs/
```

**What to observe:** `s` appears in the group execute position — `drwxrws---`. Any new file created inside this directory will automatically belong to `webstore-team` regardless of who creates it.

2. Add the sticky bit to the logs directory — only owners can delete their own files
```bash
sudo chmod +t ~/webstore/logs/
ls -ld ~/webstore/logs/
```

**What to observe:** `t` appears at the end — `drwxrws--t`.

3. View permissions in numeric form
```bash
stat ~/webstore/logs/
```

4. Remove the sticky bit
```bash
sudo chmod -t ~/webstore/logs/
```

---

## Section 6 — Break It on Purpose

### Break 1 — Exit vim the wrong way

```bash
vim ~/webstore/config/webstore.conf
```
Type some changes, then try:
```
:q
```

**What to observe:** `No write since last change` — vim refuses to quit with unsaved changes.

Fix it:
```
:wq   ← save and quit
:q!   ← quit without saving
```

### Break 2 — Wrong chmod value

```bash
sudo chmod 999 ~/webstore/config/webstore.conf
```

**What to observe:** `invalid mode` — 9 is not a valid octal digit. Valid digits are 0–7.

### Break 3 — usermod without -a drops all existing groups

```bash
# First check dev-user's current groups
groups dev-user

# Now run usermod WITHOUT -a
sudo usermod -G someothergroup dev-user

# Check groups again
groups dev-user
```

**What to observe:** `webstore-team` is gone — running `usermod -G` without `-a` replaces all supplementary groups instead of adding to them.

Fix it:
```bash
sudo usermod -aG webstore-team dev-user
groups dev-user
```

### Break 4 — Delete a user that owns files

```bash
sudo userdel webstore-svc
ls -lh ~/webstore/
```

**What to observe:** files now show a numeric UID instead of a username — the owner reference is broken because the user no longer exists.

Fix it — recreate the user and reassign ownership:
```bash
sudo useradd --system --no-create-home --shell /bin/false webstore-svc
sudo chown -R webstore-svc:webstore-team ~/webstore/
ls -lh ~/webstore/
```

---

## Checklist

Do not move to Lab 04 until every box is checked.

- [ ] I opened a file in vim, navigated with `hjkl`, jumped to a specific line with `NG`, entered insert mode, made a change, and saved with `:wq`
- [ ] I searched for a pattern in vim with `/pattern` and jumped between results with `n`
- [ ] I used `:%s/old/new/g` inside vim and then undid it with `u`
- [ ] I used `:q!` to quit vim without saving
- [ ] I created the `webstore-team` group and confirmed it in `/etc/group`
- [ ] I created `webstore-svc` as a system user with `/bin/false` shell and explained why
- [ ] I created `dev-user` as a regular user and added both `dev-user` and `www-data` to `webstore-team`
- [ ] I used `chown -R` to change ownership of the entire webstore directory tree
- [ ] I set `750` on directories, `770` on logs, and `640` on config files — and explained what each digit means
- [ ] I explained why `640` on `webstore.conf` is more secure than `644`
- [ ] I proved that `dev-user` can read the config but cannot write to it
- [ ] I applied SGID to the logs directory and saw the `s` in the group execute position
- [ ] I ran `usermod -G` without `-a` and saw group membership get wiped — then fixed it
- [ ] I deleted `webstore-svc` and saw orphaned numeric UIDs — then recreated and fixed it
