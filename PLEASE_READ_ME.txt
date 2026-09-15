**Standard Launch (GUI)**

1. Run **`Launcher.bat`** or **`Launcher.exe`** as Administrator.
2. Accept the risk disclaimer in the launcher interface.
3. Select your target privilege level to launch the application.

**Advanced Launch (Command Prompt)**

1. Open **Command Prompt** as Administrator.
2. Change directory to the application folder:
```cmd
cd /d "C:\path\to\application"

```


3. Execute `TICore.exe` with your required privilege flag:
```cmd
TICore.exe --[privilege] MynaTaskCore.exe

```


* **`--TI`**: Escalates to **TrustedInstaller** privileges.
* **`--System`**: Escalates to **SYSTEM** privileges.



**Antivirus & Defender Note**

* **False Positives:** The privilege elevation mechanism uses token duplication (impersonating system security tokens to grant higher access levels). Windows Defender or third-party antivirus applications frequently flag token manipulators as suspicious activity. If execution is blocked, add an exclusion for the application directory or temporarily disable real-time protection.