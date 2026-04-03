[🏠 Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-boot-basics-files-lab.md) |
[Lab 02](./02-filters-sed-awk-lab.md) |
[Lab 03](./03-vim-users-permissions-lab.md) |
[Lab 04](./04-archive-packages-services-lab.md) |
[Lab 05](./05-networking-lab.md)

---

# Lab 03 — Vim, Users & Permissions

## What this lab is about

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

5. Enter Insert mode and add a new line at the bottom
```
o
```
Type: `debug=false`  
Press `Esc` to return to Normal mode.

6. Search for `api_port`
```
/api_port
```
Press `n` to find the next match.

7. Replace `8080` with `8081` on that line only
```
:s/8080/8081/
```

8. Replace all occurrences of `webstore` with `ws` globally (preview what it would do)
```
:%s/webstore/ws/g
```
Undo it immediately:
```
u
```

9. Save and quit
```
:wq
```

10. Verify the change saved
```bash
cat ~/webstore/config/webstore.conf
```

11. Open the file again and quit WITHOUT saving
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

3. Create a system user for the webstore service (no home directory, no login)
```bash
sudo useradd --system --no-create-home --shell /bin/false webstore-svc
```

4. Confirm the user exists
```bash
grep webstore-svc /etc/passwd
```

5. Create a regular developer user
```bash
sudo useradd -m -s /bin/bash dev-user
sudo passwd dev-user
```

6. Add dev-user to the webstore-team group
```bash
sudo usermod -aG webstore-team dev-user
```

7. Confirm the group membership
```bash
groups dev-user
```

8. View all users
```bash
cat /etc/passwd | grep -E 'webstore|dev-user'
```

---

## Section 3 — Ownership and Permissions

**Goal:** set correct ownership and permissions on the webstore directories.

1. Check current ownership of the webstore directory
```bash
ls -lh ~/webstore/
```

2. Change ownership of the entire webstore directory to webstore-svc
```bash
sudo chown -R webstore-svc:webstore-team ~/webstore/
```

3. Confirm the change
```bash
ls -lh ~/webstore/
```

4. Set permissions on the webstore directories:
   - Owner: read + write + execute
   - Group: read + execute
   - Others: no access
```bash
sudo chmod -R 750 ~/webstore/
```

5. Confirm permissions
```bash
ls -lh ~/webstore/
```

6. The logs directory should be writable by the group (service needs to write logs)
```bash
sudo chmod 770 ~/webstore/logs/
ls -lh ~/webstore/
```

7. Config files should be read-only for the group
```bash
sudo chmod 640 ~/webstore/config/webstore.conf
ls -lh ~/webstore/config/
```

---

## Section 4 — Verify Access Control

**Goal:** prove permissions actually block or allow access as expected.

1. Try to read the config as the current user
```bash
cat ~/webstore/config/webstore.conf
```

2. Try to read as dev-user (who is in webstore-team group)
```bash
sudo -u dev-user cat ~/webstore/config/webstore.conf
```

**What to observe:** dev-user can read (group has r permission)

3. Try to write to the config as dev-user
```bash
sudo -u dev-user bash -c 'echo "test" >> ~/webstore/config/webstore.conf'
```

**What to observe:** permission denied — group only has read on config files

4. Try to write to the logs directory as dev-user
```bash
sudo -u dev-user bash -c 'echo "test log entry" >> /home/$USER/webstore/logs/access.log'
```

**What to observe:** permitted — logs directory has 770 (group can write)

---

## Section 5 — Special Permissions

**Goal:** apply and observe the sticky bit.

1. Add the sticky bit to the logs directory
```bash
sudo chmod +t ~/webstore/logs/
ls -lh ~/webstore/
```

**What to observe:** `t` appears at the end of the permissions string (e.g. `drwxrwx--t`)

2. View permissions in numeric form
```bash
stat ~/webstore/logs/
```

3. Remove the sticky bit
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

**What to observe:** `No write since last change` — vim refuses to quit when there are unsaved changes

Fix it with one of:
```
:wq   ← save and quit
:q!   ← quit without saving
```

### Break 2 — Wrong chmod value

```bash
sudo chmod 999 ~/webstore/config/webstore.conf
```

**What to observe:** `invalid mode` — 9 is not a valid octal digit (max is 7)

### Break 3 — Delete a user that owns files

```bash
sudo userdel webstore-svc
ls -lh ~/webstore/
```

**What to observe:** the files now show a numeric UID instead of a username — the owner reference is broken

Fix it — recreate the user and reassign:
```bash
sudo useradd --system --no-create-home --shell /bin/false webstore-svc
sudo chown -R webstore-svc:webstore-team ~/webstore/
```

---

## Checklist

Do not move to Lab 04 until every box is checked.

- [ ] I opened a file in vim, navigated with `hjkl`, entered insert mode, made a change, and saved with `:wq`
- [ ] I searched for a pattern in vim with `/pattern` and jumped between results with `n`
- [ ] I used `:%s/old/new/g` inside vim and then undid it with `u`
- [ ] I used `:q!` to quit vim without saving
- [ ] I created the `webstore-team` group and confirmed it in `/etc/group`
- [ ] I created `webstore-svc` as a system user and `dev-user` as a regular user
- [ ] I added `dev-user` to `webstore-team` and confirmed with `groups dev-user`
- [ ] I used `chown -R` to change ownership of the entire webstore directory tree
- [ ] I set `750` on directories and `640` on config files and explained what each digit means
- [ ] I proved that `dev-user` can read the config but cannot write to it
- [ ] I applied and removed the sticky bit and saw the `t` appear and disappear in `ls -lh`
- [ ] I deleted `webstore-svc` and saw orphaned numeric UIDs — then fixed it
