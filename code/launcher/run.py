"""CampusCare - run the whole project on this computer with one command.

Started by  mac/run.sh  or  windows\\run.bat.  It
  1. downloads the tools it needs into code/.tools (nothing is installed on
     the computer itself - delete that folder to get the disk space back),
  2. starts the local backend: the Firebase emulators and the AI service,
  3. fills the local database with demo data,
  4. boots an Android phone emulator, installs the app and opens it.

Everything runs on this machine (localhost); no account or key is needed.
Standard library only, so it runs on the bare Python the start script fetches.

A second use, for after you have connected your OWN Firebase project
(guidelines/05-firebase):

    run.sh cloud scripts/seed.py
    run.sh cloud scripts/make_admin.py someone@college.edu

runs one of the project's Python tools against that project, using the
values in code/keys/.
"""
from __future__ import annotations

import os
import shutil
import signal
import socket
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

WIN = os.name == "nt"
HERE = Path(__file__).resolve().parent
CODE = HERE.parent
TOOLS = CODE / ".tools"
DOWNLOADS = TOOLS / "downloads"
LOGS = TOOLS / "logs"
SDK = TOOLS / "android-sdk"
PYLIB = TOOLS / "pylib"  # short on purpose: Windows paths stop at 260 characters
APK = HERE / "CampusCare-local.apk"
KEYS = CODE / "keys"

PROJECT = "demo-campuscare"  # "demo-" ids are emulator-only: no real Firebase project is touched
PACKAGE = "com.gat.grievance_app"
AVD = "campuscare"
INSIDE_CAMPUS = ("77.52640", "12.92665")  # longitude, latitude of the canteen
PORTS = {9099: "login service", 8080: "database", 9199: "file storage",
         4000: "database viewer", 8000: "AI service"}

# ---------------------------------------------------------------------------
# What gets downloaded. Versions are pinned to the set this project was
# tested with, so a new release somewhere cannot break the run.
# ---------------------------------------------------------------------------
_G = "https://dl.google.com/android/repository/"
_J = ("https://github.com/adoptium/temurin21-binaries/releases/download/"
      "jdk-21.0.13.1%2B2/OpenJDK21U-jre_")
_N = "https://nodejs.org/dist/v24.19.0/node-v24.19.0-"
_IMG = "android-sdk/system-images/android-35/google_apis/"
FIREBASE_TOOLS = "15.27.0"

# platform -> [(what, folder inside .tools, url, size in bytes)]
TOOLSET = {
    "mac-arm": [
        ("Java runtime", "java", _J + "aarch64_mac_hotspot_21.0.13.1_2.tar.gz", 47946379),
        ("Node.js", "node", _N + "darwin-arm64.tar.gz", 52234372),
        ("Android tools", "android-sdk/platform-tools", _G + "platform-tools_r37.0.3-darwin.zip", 16597626),
        ("Android emulator", "android-sdk/emulator", _G + "emulator-darwin_aarch64-16970787.zip", 420629851),
        ("Android 15 phone image", _IMG + "arm64-v8a", _G + "sys-img/google_apis/arm64-v8a-35_r09.zip", 1778933980),
    ],
    "mac-intel": [
        ("Java runtime", "java", _J + "x64_mac_hotspot_21.0.13.1_2.tar.gz", 41907486),
        ("Node.js", "node", _N + "darwin-x64.tar.gz", 53439583),
        ("Android tools", "android-sdk/platform-tools", _G + "platform-tools_r37.0.3-darwin.zip", 16597626),
        ("Android emulator", "android-sdk/emulator", _G + "emulator-darwin_x64-16970787.zip", 487638528),
        ("Android 15 phone image", _IMG + "x86_64", _G + "sys-img/google_apis/x86_64-35_r09.zip", 1738815903),
    ],
    "win": [
        ("Java runtime", "java", _J + "x64_windows_hotspot_21.0.13.1_2.zip", 49108427),
        ("Node.js", "node", _N + "win-x64.zip", 37304352),
        ("Android tools", "android-sdk/platform-tools", _G + "platform-tools_r37.0.3-win.zip", 8188601),
        ("Android emulator", "android-sdk/emulator", _G + "emulator-windows_x64-16970787.zip", 456613348),
        ("Android 15 phone image", _IMG + "x86_64", _G + "sys-img/google_apis/x86_64-35_r09.zip", 1738815903),
    ],
}

AVD_CONFIG = """\
AvdId = {avd}
PlayStore.enabled = no
abi.type = {abi}
avd.ini.displayname = CampusCare phone
avd.ini.encoding = UTF-8
disk.dataPartition.size = 6442450944
fastboot.forceColdBoot = yes
hw.accelerometer = yes
hw.audioInput = yes
hw.audioOutput = yes
hw.battery = yes
hw.camera.back = emulated
hw.camera.front = none
hw.cpu.arch = {cpu}
hw.cpu.ncore = 4
hw.dPad = no
hw.gps = yes
hw.gpu.enabled = yes
hw.gpu.mode = auto
hw.keyboard = yes
hw.lcd.density = 420
hw.lcd.height = 2400
hw.lcd.width = 1080
hw.mainKeys = no
hw.ramSize = 2048
hw.sdCard = yes
hw.sensors.orientation = yes
hw.sensors.proximity = yes
hw.trackBall = no
image.sysdir.1 = system-images/android-35/google_apis/{abi}/
sdcard.size = 512M
showDeviceFrame = no
skin.dynamic = yes
skin.name = 1080x2400
skin.path = _no_skin
tag.display = Google APIs
tag.id = google_apis
vm.heapSize = 228
"""

if WIN:
    _SYS = Path(os.environ.get("SystemRoot", r"C:\Windows")) / "System32"
    CURL, TAR = str(_SYS / "curl.exe"), str(_SYS / "tar.exe")
    POWERSHELL = str(_SYS / "WindowsPowerShell" / "v1.0" / "powershell.exe")
    JAVA_HOME = TOOLS / "java"
    NODE = TOOLS / "node" / "node.exe"
    NPM = TOOLS / "node" / "node_modules" / "npm" / "bin" / "npm-cli.js"
    EXE = ".exe"
else:
    CURL, TAR = "/usr/bin/curl", "/usr/bin/tar"
    JAVA_HOME = TOOLS / "java" / "Contents" / "Home"
    NODE = TOOLS / "node" / "bin" / "node"
    NPM = TOOLS / "node" / "lib" / "node_modules" / "npm" / "bin" / "npm-cli.js"
    EXE = ""
ADB = SDK / "platform-tools" / ("adb" + EXE)
EMULATOR = SDK / "emulator" / ("emulator" + EXE)
FIREBASE_DIR = TOOLS / "firebase"
FIREBASE_JS = FIREBASE_DIR / "node_modules" / "firebase-tools" / "lib" / "bin" / "firebase.js"

RUNNING: list[tuple[str, subprocess.Popen]] = []  # (log name, process) we started
PHONE = {"serial": "", "env": None}


def say(text: str = "") -> None:
    print(text, flush=True)


def die(message: str) -> None:
    say()
    say("  PROBLEM: " + message.replace("\n", "\n  "))
    say()
    raise SystemExit(1)


def detect_platform() -> str:
    if WIN:
        arch = os.environ.get("PROCESSOR_ARCHITEW6432") or os.environ.get("PROCESSOR_ARCHITECTURE", "")
        if arch.upper() != "AMD64":
            die("This needs a 64-bit Intel or AMD Windows PC.\n"
                "The Android emulator does not run on Windows-on-ARM laptops.")
        return "win"
    if sys.platform == "darwin":
        arm = subprocess.run(["/usr/sbin/sysctl", "-n", "hw.optional.arm64"],
                             capture_output=True, text=True).stdout.strip() == "1"
        return "mac-arm" if arm else "mac-intel"
    die("Only macOS and Windows are supported.")
    return ""


# ---------------------------------------------------------------------------
# Downloading and unpacking
# ---------------------------------------------------------------------------
def remove(path: Path) -> None:
    def writable_then_retry(func, target, _exc):
        os.chmod(target, 0o700)
        func(target)

    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path, onexc=writable_then_retry)
    elif path.exists() or path.is_symlink():
        path.unlink()


def download(url: str, size: int, dest: Path) -> None:
    """Resumable: a dropped connection continues where it stopped."""
    dest.parent.mkdir(parents=True, exist_ok=True)
    for attempt in range(1, 13):
        have = dest.stat().st_size if dest.exists() else 0
        if have == size:
            return
        if have > size:
            dest.unlink()
        if attempt > 1:
            say(f"      connection dropped - continuing the download (try {attempt} of 12)")
            time.sleep(5)
        subprocess.run([CURL, "-fL", "-#", "-C", "-", "--connect-timeout", "30",
                        "--speed-limit", "2000", "--speed-time", "60",
                        "-o", str(dest), url])
    if not dest.exists() or dest.stat().st_size != size:
        die("A download could not be completed.\n"
            "Check the internet connection and run the same command again -\n"
            "it continues from where it stopped.")


def fetch(what: str, folder: str, url: str, size: int) -> None:
    dest = TOOLS / folder
    if (dest / ".ready").exists():
        return
    say(f"    - {what} ({size / 1e6:.0f} MB)")
    archive = DOWNLOADS / url.rsplit("/", 1)[1]
    download(url, size, archive)
    remove(dest)
    dest.mkdir(parents=True)
    # Every archive holds one top folder; dropping it puts the files in place
    # directly, which also keeps paths short enough for Windows.
    if subprocess.run([TAR, "-xf", str(archive), "-C", str(dest),
                       "--strip-components", "1"]).returncode != 0:
        remove(archive)
        die(f"Could not unpack {what}.\nRun the same command again to download it afresh.")
    (dest / ".ready").touch()
    remove(archive)


def run_with_retries(what: str, cmd: list, env: dict) -> None:
    for attempt in range(3):
        if attempt:
            say(f"      trying again ({attempt + 1} of 3)")
            time.sleep(5)
        if subprocess.run([str(c) for c in cmd], env=env).returncode == 0:
            return
    die(f"Could not install {what}.\nCheck the internet connection and run the same command again.")


def install_python_packages(env: dict) -> None:
    requirements = CODE / "ai-service" / "requirements.txt"
    stamp = PYLIB / ".ready"
    if not stamp.exists() or stamp.read_bytes() != requirements.read_bytes():
        say("    - Python packages for the AI service (takes a few minutes)")
        remove(PYLIB)
        run_with_retries("the Python packages", [
            sys.executable, "-m", "pip", "install", "--quiet",
            "--disable-pip-version-check", "--no-cache-dir", "--no-compile",
            "--target", PYLIB, "-r", requirements], env)
        stamp.write_bytes(requirements.read_bytes())


def install_tools(plat: str, env: dict) -> None:
    for what, folder, url, size in TOOLSET[plat]:
        fetch(what, folder, url, size)
    install_python_packages(env)
    if not (FIREBASE_DIR / ".ready").exists():
        say("    - Firebase local emulators (takes a few minutes)")
        FIREBASE_DIR.mkdir(parents=True, exist_ok=True)
        run_with_retries("the Firebase emulators", [
            NODE, NPM, "install", "--prefix", FIREBASE_DIR, "--no-audit",
            "--no-fund", "--loglevel=error", f"firebase-tools@{FIREBASE_TOOLS}"], env)
        (FIREBASE_DIR / ".ready").touch()
        remove(TOOLS / "npm-cache")


# ---------------------------------------------------------------------------
# Processes
# ---------------------------------------------------------------------------
def build_env() -> dict:
    """Environment for everything we start: only our own tools, no leftovers
    from other Python/Node/Android installs on this computer."""
    env = {k: v for k, v in os.environ.items()
           if not k.upper().startswith("PYTHON") and k.upper() != "NODE_OPTIONS"}
    env["PATH"] = os.pathsep.join([str(JAVA_HOME / "bin"), str(NODE.parent),
                                   str(ADB.parent), env.get("PATH", "")])
    env.update(
        JAVA_HOME=str(JAVA_HOME),
        ANDROID_HOME=str(SDK), ANDROID_SDK_ROOT=str(SDK),
        ANDROID_AVD_HOME=str(TOOLS / "avd"),
        XDG_CONFIG_HOME=str(TOOLS / "config"),
        FIREBASE_EMULATORS_PATH=str(TOOLS / "firebase-emulators"),
        npm_config_cache=str(TOOLS / "npm-cache"),
        npm_config_update_notifier="false", NO_UPDATE_NOTIFIER="1",
        PYTHONUNBUFFERED="1", PYTHONDONTWRITEBYTECODE="1",
    )
    return env


def backend_env(env: dict) -> dict:
    """Points the seed script and the AI service at the local emulators."""
    return {**env, "PYTHONPATH": str(PYLIB),
            "FIREBASE_PROJECT_ID": PROJECT, "GCLOUD_PROJECT": PROJECT,
            "FIRESTORE_EMULATOR_HOST": "127.0.0.1:8080",
            "FIREBASE_AUTH_EMULATOR_HOST": "127.0.0.1:9099"}


def kill_strays() -> None:
    """Stop everything still running out of .tools: a previous run that was
    closed badly, or our own children (and theirs) at the end of this one."""
    prefix = str(TOOLS) + os.sep
    if WIN:
        script = (
            "Get-CimInstance Win32_Process | Where-Object { $_.ExecutablePath -and "
            "$_.ExecutablePath.StartsWith($env:CC_TOOLS, [StringComparison]::OrdinalIgnoreCase) "
            "-and $_.ProcessId -ne [int]$env:CC_SELF } | ForEach-Object { "
            "Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }")
        subprocess.run([POWERSHELL, "-NoProfile", "-NonInteractive", "-Command", script],
                       env={**os.environ, "CC_TOOLS": prefix, "CC_SELF": str(os.getpid())},
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return
    listing = subprocess.run(["/bin/ps", "-axww", "-o", "pid=,command="],
                             capture_output=True, text=True, errors="replace").stdout
    for line in listing.splitlines():
        pid, _, command = line.strip().partition(" ")
        if prefix in command and pid.isdigit() and int(pid) != os.getpid():
            try:
                os.kill(int(pid), signal.SIGKILL)
            except OSError:
                pass


def port_busy(port: int) -> bool:
    with socket.socket() as probe:
        probe.settimeout(1)
        return probe.connect_ex(("127.0.0.1", port)) == 0


def http_ok(url: str) -> bool:
    try:
        with urllib.request.urlopen(url, timeout=3) as reply:
            return reply.status == 200
    except OSError:
        return False


def start(name: str, cmd: list, cwd: Path, env: dict) -> subprocess.Popen:
    log = open(LOGS / f"{name}.log", "w")
    proc = subprocess.Popen([str(c) for c in cmd], cwd=str(cwd), env=env,
                            stdin=subprocess.DEVNULL, stdout=log,
                            stderr=subprocess.STDOUT)
    RUNNING.append((name, proc))
    return proc


def stop(proc: subprocess.Popen) -> None:
    RUNNING[:] = [(n, p) for n, p in RUNNING if p is not proc]
    if proc.poll() is not None:
        return
    if WIN:  # /T also stops what it started (the emulator's qemu, Firebase's java)
        subprocess.run(["taskkill", "/PID", str(proc.pid), "/T", "/F"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    else:
        proc.terminate()
    try:
        proc.wait(timeout=15)
    except subprocess.TimeoutExpired:
        proc.kill()


def log_tail(name: str, lines: int = 25) -> str:
    path = LOGS / f"{name}.log"
    try:
        text = path.read_text(errors="replace").strip().splitlines()[-lines:]
    except OSError:
        text = []
    return f"Last lines of {path}:\n" + "\n".join("    " + t for t in text)


def wait_for(title: str, name: str, proc: subprocess.Popen, ready, minutes: int) -> None:
    deadline = time.time() + minutes * 60
    while time.time() < deadline:
        if ready():
            return
        if proc.poll() is not None:
            die(f"{title} stopped while starting.\n{log_tail(name)}")
        time.sleep(1)
    die(f"{title} did not start within {minutes} minutes.\n{log_tail(name)}")


# ---------------------------------------------------------------------------
# Android phone
# ---------------------------------------------------------------------------
def adb(*args: str, timeout: int = 120) -> subprocess.CompletedProcess:
    cmd = [str(ADB), "-s", PHONE["serial"], *args]
    try:
        return subprocess.run(cmd, capture_output=True, text=True, errors="replace",
                              timeout=timeout, env=PHONE["env"], stdin=subprocess.DEVNULL)
    except subprocess.TimeoutExpired:
        return subprocess.CompletedProcess(cmd, 1, "", "timed out")


def check_windows_acceleration(env: dict) -> None:
    """The emulator needs a hypervisor. Windows ships one (Windows Hypervisor
    Platform) but it is switched off by default on many PCs."""
    result = subprocess.run([str(EMULATOR), "-accel-check"], capture_output=True,
                            text=True, errors="replace", env=env)
    lines = [l.strip() for l in result.stdout.splitlines() if l.strip()]
    code = result.returncode
    if "accel:" in lines and lines.index("accel:") + 1 < len(lines):
        number = lines[lines.index("accel:") + 1]
        code = int(number) if number.isdigit() else code
    if code == 0:
        return
    detail = " ".join(l for l in lines if l not in ("accel:", "accel") and not l.isdigit())
    say()
    say("  The Android phone emulator needs 'Windows Hypervisor Platform',")
    say("  which is not usable on this PC yet.")
    say(f"  ({detail})")
    say()
    say("  Switching it on now - Windows will ask for permission: click YES.")
    subprocess.run([POWERSHELL, "-NoProfile", "-Command",
                    "Start-Process dism.exe -Verb RunAs -Wait -ArgumentList "
                    "'/online','/enable-feature','/featurename:HypervisorPlatform','/all','/norestart'"])
    die("RESTART the PC now, then run this same command again.\n"
        "If you see this message again after the restart, virtualization is\n"
        "switched off in the BIOS/UEFI settings of the PC: turn on\n"
        "'Intel Virtualization Technology (VT-x)' or 'AMD SVM' there.")


def write_phone_definition(abi: str) -> None:
    home = TOOLS / "avd"
    device = home / f"{AVD}.avd"
    device.mkdir(parents=True, exist_ok=True)
    # Rewritten every run: it holds an absolute path, and the folder may have moved.
    (home / f"{AVD}.ini").write_text(
        f"avd.ini.encoding=UTF-8\npath={device}\ntarget=android-35\n", encoding="utf-8")
    config = device / "config.ini"
    if not config.exists():
        config.write_text(AVD_CONFIG.format(
            avd=AVD, abi=abi, cpu="arm64" if abi == "arm64-v8a" else "x86_64"))


def free_console_port() -> int:
    for port in range(5554, 5584, 2):  # another emulator may already own 5554
        if not port_busy(port) and not port_busy(port + 1):
            return port
    die("Too many Android emulators are already open. Close them and run again.")
    return 0


def phone_booted(emulator: subprocess.Popen) -> bool:
    """True once Android has finished booting. Gives up early when the phone
    never even appears (a graphics hang) so that the caller can retry."""
    began = time.time()
    appeared = False
    while emulator.poll() is None:
        waited = time.time() - began
        if adb("get-state", timeout=20).stdout.strip() == "device":
            appeared = True
            if adb("shell", "getprop", "sys.boot_completed", timeout=20).stdout.strip() == "1":
                return True
        if (not appeared and waited > 5 * 60) or waited > 25 * 60:
            return False
        time.sleep(3)
    return False


def boot_phone(env: dict, abi: str) -> subprocess.Popen:
    write_phone_definition(abi)
    port = free_console_port()
    PHONE.update(serial=f"emulator-{port}", env=env)
    # CAMPUSCARE_GPU=swiftshader_indirect (software) or host forces one mode.
    forced = os.environ.get("CAMPUSCARE_GPU")
    modes = [forced] if forced else ["auto", "swiftshader_indirect"]
    for index, gpu in enumerate(modes):
        emulator = start("android-emulator", [
            EMULATOR, "-avd", AVD, "-port", port, "-gpu", gpu,
            "-no-snapshot", "-no-boot-anim", "-no-metrics"], TOOLS, env)
        if phone_booted(emulator):
            return emulator
        stop(emulator)
        if index + 1 < len(modes):
            say("      the phone did not come up - trying software graphics "
                "(slower, but works on every computer)")
    die(f"The Android phone emulator did not start.\n{log_tail('android-emulator')}")
    return emulator


def link_phone_to_computer() -> None:
    """The emulated phone has two links: mobile data and Wi-Fi. Now and then
    Android brings the Wi-Fi one up without a route, and then nothing on the
    phone can reach this computer (the app says "Could not sign in"). Mobile
    data always routes correctly, so that is the only link left on. Then
    prove the phone really reaches the backend before going on."""
    adb("shell", "svc", "wifi", "disable")
    probe = "nc -w 3 10.0.2.2 9099 </dev/null >/dev/null 2>&1 && echo open"
    for _ in range(30):
        if "open" in adb("shell", probe, timeout=20).stdout:
            return
        time.sleep(2)
    die("The phone emulator cannot reach the services on this computer.\n"
        "Run the same command again.")


def install_app() -> None:
    for _ in range(60):  # the package manager comes up a little after boot
        if "package:" in adb("shell", "pm", "path", "android").stdout:
            break
        time.sleep(2)
    # Fresh install each run: a login kept from an older run would not exist
    # in the freshly filled database.
    adb("uninstall", PACKAGE)
    result = None
    for _ in range(5):
        result = adb("install", "-r", "-g", str(APK), timeout=600)
        if "Success" in result.stdout:
            break
        time.sleep(5)
    else:
        die("Could not install the app on the phone emulator.\n"
            + (result.stdout + result.stderr).strip()[-800:])
    adb("emu", "geo", "fix", *INSIDE_CAMPUS)  # put the phone inside the campus
    # The phone's network comes up a few seconds after boot, and the app
    # fetches its font online on first start: opened too early, it falls back
    # to the system font. Offline, this just gives up after 20 seconds.
    for _ in range(10):
        if adb("shell", "ping", "-c", "1", "-W", "2", "fonts.gstatic.com", timeout=10).returncode == 0:
            break
        time.sleep(2)
    adb("shell", "am", "start", "-n", f"{PACKAGE}/.MainActivity")


# ---------------------------------------------------------------------------
def shutdown() -> None:
    if RUNNING:
        say()
        say("  Stopping everything ...")
    emulators = [p for n, p in RUNNING if n == "android-emulator"]
    if emulators and emulators[0].poll() is None:
        adb("emu", "kill", timeout=15)  # lets Android shut down cleanly
        try:
            emulators[0].wait(timeout=20)
        except subprocess.TimeoutExpired:
            pass
    for _, proc in list(RUNNING):
        stop(proc)
    if ADB.exists():  # its background server shows up as plain "adb", not by path
        subprocess.run([str(ADB), "kill-server"], capture_output=True, timeout=30)
    if TOOLS.exists():
        kill_strays()


def check_before_start() -> None:
    if not APK.exists():
        die(f"The app file is missing: {APK}\nCopy the project folder again from the original zip.")
    if WIN and len(str(CODE)) > 125:
        die("This folder sits too deep on the disk for Windows.\n"
            "Move the whole project folder to a short place such as C:\\CampusCare\n"
            "and run the command again.")
    try:
        str(CODE).encode("ascii")
    except UnicodeEncodeError:
        die("The folder path contains special (non-English) characters, which the\n"
            "Android emulator cannot handle. Move the project folder to a simple\n"
            "place such as C:\\CampusCare (Windows) or your home folder (Mac).")
    TOOLS.mkdir(exist_ok=True)
    LOGS.mkdir(exist_ok=True)
    kill_strays()
    time.sleep(1)
    busy = [f"{port} ({name})" for port, name in PORTS.items() if port_busy(port)]
    if busy:
        die("Another program on this computer is using a port this project needs:\n    "
            + ", ".join(busy)
            + "\nClose that program (or simply restart the computer) and run again.")
    first_boot_done = (TOOLS / "avd" / f"{AVD}.avd" / "userdata-qemu.img").exists()
    need = 3 if first_boot_done else 14
    free = shutil.disk_usage(TOOLS).free / 1e9
    if free < need:
        die(f"Not enough free disk space: {free:.0f} GB free, about {need} GB needed.\n"
            "Free some space and run the command again.")


def main() -> None:
    plat = detect_platform()
    say()
    say("  CampusCare - local run")
    say("  ======================")
    check_before_start()
    env = build_env()
    abi = "arm64-v8a" if plat == "mac-arm" else "x86_64"

    say()
    say("  [1/5] Tools (the first run downloads about 3 GB; later runs skip this)")
    install_tools(plat, env)
    if WIN:
        check_windows_acceleration(env)

    say("  [2/5] Local backend: database, login and storage")
    run_dir = TOOLS / "run"
    run_dir.mkdir(exist_ok=True)
    firebase = start("firebase", [
        NODE, FIREBASE_JS, "emulators:start", "--project", PROJECT,
        "--config", CODE / "firebase" / "firebase.json",
        "--only", "auth,firestore,storage"], run_dir, env)
    wait_for("The local backend", "firebase", firebase,
             lambda: all(port_busy(p) for p in (9099, 8080, 9199, 4000)), 10)

    say("  [3/5] Demo data and the AI service")
    service_dir = CODE / "ai-service"
    with open(LOGS / "seed.log", "w") as log:
        seeded = subprocess.run([sys.executable, "scripts/seed.py"], cwd=str(service_dir),
                                env=backend_env(env), stdout=log, stderr=subprocess.STDOUT)
    if seeded.returncode != 0:
        die(f"Could not fill the local database with demo data.\n{log_tail('seed')}")
    service = start("ai-service", [
        sys.executable, "-m", "uvicorn", "main:app", "--host", "127.0.0.1",
        "--port", "8000"], service_dir, backend_env(env))
    wait_for("The AI service", "ai-service", service,
             lambda: http_ok("http://127.0.0.1:8000/health"), 5)

    say("  [4/5] Android phone (the first start takes a few minutes)")
    emulator = boot_phone(env, abi)

    say("  [5/5] Installing and opening the CampusCare app")
    link_phone_to_computer()
    install_app()

    say()
    say("  ==============================================================")
    say("    Local host is ready")
    say("  ==============================================================")
    say("    The CampusCare app is open on the Android phone on your screen.")
    say()
    say("    Log in with    student@demo.com    password123    (student)")
    say("                   admin@demo.com      password123    (college admin)")
    say("    The other logins are listed in code/README.md.")
    say()
    say("    Running on this computer:")
    say("      Database viewer    http://localhost:4000")
    say("      AI service         http://localhost:8000/docs")
    say()
    say("    Keep this window open while you use the app.")
    say("    To stop everything: press Ctrl+C here, or close the phone window.")
    say("  ==============================================================")

    while emulator.poll() is None:
        time.sleep(2)
        for name, proc in RUNNING:
            if proc is not emulator and proc.poll() is not None:
                die(f"A background service stopped unexpectedly.\n{log_tail(name)}")
    say()
    say("  The phone window was closed.")


def run_on_own_firebase(args: list) -> None:
    """`cloud <script.py> [options]`: run a Python tool from ai-service/
    against YOUR Firebase project instead of the local emulators."""
    env_file, account = KEYS / "keys.env", KEYS / "serviceAccount.json"
    keys = {}
    if env_file.exists():
        for line in env_file.read_text(encoding="utf-8", errors="replace").splitlines():
            name, sep, value = line.strip().partition("=")
            if sep and not name.startswith("#"):
                keys[name.strip()] = value.strip()
    if not args:
        die("Say which tool to run, for example:\n"
            "    cloud scripts/seed.py\n"
            "    cloud scripts/make_admin.py someone@college.edu")
    if not keys.get("FIREBASE_PROJECT_ID"):
        die("FIREBASE_PROJECT_ID is empty in code/keys/keys.env.\n"
            "Fill in the keys file first: guidelines/04-keys.")
    if not account.exists():
        die("code/keys/serviceAccount.json is missing.\n"
            "Download it from your Firebase project and save it there with\n"
            "exactly that name: guidelines/05-firebase, step 7.")
    detect_platform()
    TOOLS.mkdir(exist_ok=True)
    env = build_env()
    install_python_packages(env)
    for name in ("FIRESTORE_EMULATOR_HOST", "FIREBASE_AUTH_EMULATOR_HOST"):
        env.pop(name, None)  # a leftover would silently send this to an emulator
    env.update(PYTHONPATH=str(PYLIB), SEED_TARGET="prod",
               FIREBASE_PROJECT_ID=keys["FIREBASE_PROJECT_ID"],
               GCLOUD_PROJECT=keys["FIREBASE_PROJECT_ID"],
               GOOGLE_APPLICATION_CREDENTIALS=str(account))
    say(f"  Firebase project: {keys['FIREBASE_PROJECT_ID']}")
    done = subprocess.run([sys.executable, *args], cwd=str(CODE / "ai-service"), env=env)
    raise SystemExit(done.returncode)


def _interrupt(*_):
    raise KeyboardInterrupt


if __name__ == "__main__":
    sys.stdout.reconfigure(errors="replace")
    if sys.argv[1:2] == ["cloud"]:
        run_on_own_firebase(sys.argv[2:])
    for _name in ("SIGTERM", "SIGHUP"):  # closing the terminal window = Ctrl+C
        if hasattr(signal, _name):
            signal.signal(getattr(signal, _name), _interrupt)
    try:
        main()
    except KeyboardInterrupt:
        pass
    finally:
        try:
            shutdown()
        except KeyboardInterrupt:
            kill_strays()
    say("  Stopped. Run the same command again any time.")
