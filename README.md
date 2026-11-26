# CampusCare

**AI-Based Student Grievance Management System for Smart Campus**
Global Academy of Technology · Department of Information Science & Engineering

| Folder | What is inside |
|---|---|
| `code/` | The complete project (Android app, AI service, database rules) and a one-command local run |
| `docs/` | Research paper, presentation, poster and project report |
| `guidelines/` | The guides: start with `guidelines/00-START-HERE.pdf` |

## Run the project on your computer

One command. It downloads what it needs into this folder, starts everything
on your own computer (localhost) and opens the app on an Android phone
emulator. No account, no key and no installation is needed.

**Mac** — open Terminal, type `bash ` (with the space), drag the file
`code/mac/run.sh` into the Terminal window and press Enter:

```
bash code/mac/run.sh
```

**Windows** — open the folder `code\windows` and double-click `run.bat`,
or type this in Command Prompt from this folder:

```
code\windows\run.bat
```

Those two lines need the window to be inside this folder. With the folder's
location in front, the command works from anywhere. For a folder kept in
Downloads:

```
bash ~/Downloads/Project_Grievance_Management_System_Global/code/mac/run.sh
```

```
"%USERPROFILE%\Downloads\Project_Grievance_Management_System_Global\code\windows\run.bat"
```

When it prints **Local host is ready**, the app is open on the phone on your
screen. Log in with `student@demo.com` or `admin@demo.com`, password
`password123`.

You need: an internet connection for the first run (about 3 GB is
downloaded), 15 GB of free disk space and 8 GB of RAM. Windows 10/11 64-bit,
or macOS 12 and newer.

## The guides

| Guide | For |
|---|---|
| `guidelines/00-START-HERE.pdf` | What to open first |
| `guidelines/01-overview/` | What the project does; how the code is organised |
| `guidelines/02-how-to-run/` | Running it, step by step, with troubleshooting |
| `guidelines/03-access/` | Every login and every address |
| `guidelines/04-keys/` | The keys the project can use, and where yours go |
| `guidelines/05-firebase/` | Creating your own Firebase project |
| `guidelines/06-hosting/` | Hosting the AI service; building the app for real phones |
| `guidelines/07-showcase/` | LinkedIn, X and resume |
| `guidelines/08-completion/` | What was delivered and tested |

This folder contains no keys and is connected to no account. Anything you
connect it to is your own, and goes in `code/keys/`.
