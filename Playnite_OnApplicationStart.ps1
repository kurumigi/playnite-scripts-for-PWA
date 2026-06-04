# ----------------------------------------------------------
# Get a list of main windows to record playtime of browser games and more.
#
# ブラウザゲームなどのプレイ時間を記録するために、メインウィンドウの一覧を取得します。
# ----------------------------------------------------------
#
# Reference / Source:
#   Old method (ClassName and WindowTitle / C#):
#     https://stackoverflow.com/questions/16958051/get-chrome-browser-title-using-c-sharp
#     https://raykeymas.com/posts/powershell/get-chrome-window (Japanese)
#   Current method (Program Name and WindowTitle / Powershell):
#     https://qiita.com/Tadataka_Takahashi/items/91c42661ef9559ac5f86 (Japanese)
#     https://note.com/kaito_mishima/n/n99cdce0b72f0 (Japanese)
#   Current method (Program Name and WindowTitle / C#):
#     https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-overview?view=powershell-5.1
#   Imports a cmdlet written in C# within a .ps1 file as a PowerShell module:
#     https://devblogs.microsoft.com/powershell/dynamic-binary-modules/
#     https://gist.github.com/guitarrapc/e398672bcb26814b6328
#
# ----------------------------------------------------------

# Get a list of main windows.
#
# メインウィンドウの一覧を取得します。
$CSData = Add-Type @"
using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Linq;
using System.Runtime.InteropServices;
using System.Management.Automation;    // Windows PowerShell namespace.
using System.Text;

    #region GetWindowsCommand
    /// <summary>
    /// This class implements the Get-Windows cmdlet.
    /// </summary>
    [Cmdlet(VerbsCommon.Get, "Windows")]
    public class GetWindowsCommand : Cmdlet
    {
        #region private Members
        /// <summary>
        /// This list stores handles of current windows.
        /// </summary>
        private List<IntPtr> windowHandles;

        /// <summary>
        /// This array stores information about current processes.
        /// </summary>
        private Process[] processes;
        #endregion private Members

        #region Parameters
        /// <summary>
        /// The process IDs of the windows to act on.
        /// </summary>
        private uint[] Ids;

        /// <summary>
        /// Gets or sets the list of process IDs on
        /// which the Get-Windows cmdlet will work.
        /// </summary>
        [Parameter(
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true)]
        public uint[] Id
        {
            get { return this.Ids; }
            set { this.Ids = value; }
        }

        /// <summary>
        /// The process paths of the windows to act on.
        /// </summary>
        private string[] processPaths;

        /// <summary>
        /// Gets or sets the list of process paths on
        /// which the Get-Windows cmdlet will work.
        /// </summary>
        [Parameter(
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true)]
        [Alias("Path")]
        public string[] ProcessPath
        {
            get { return this.processPaths; }
            set { this.processPaths = value; }
        }

        /// <summary>
        /// The process names of the windows to act on.
        /// </summary>
        private string[] processNames;

        /// <summary>
        /// Gets or sets the list of process names on
        /// which the Get-Windows cmdlet will work.
        /// </summary>
        [Parameter(
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true)]
        [Alias("Name")]
        public string[] ProcessName
        {
            get { return this.processNames; }
            set { this.processNames = value; }
        }

        /// <summary>
        /// The ClassNames of the windows to act on.
        /// </summary>
        private string[] classNames;

        /// <summary>
        /// Gets or sets the list of ClassNames on
        /// which the Get-Windows cmdlet will work.
        /// </summary>
        [Parameter(
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true)]
        public string[] ClassName
        {
            get { return this.classNames; }
            set { this.classNames = value; }
        }

        /// <summary>
        /// The titles of the windows to act on.
        /// </summary>
        private string[] windowTitles;

        /// <summary>
        /// Gets or sets the list of titles on
        /// which the Get-Windows cmdlet will work.
        /// </summary>
        [Parameter(
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true)]
        [Alias("Title")]
        public string[] WindowTitle
        {
            get { return this.windowTitles; }
            set { this.windowTitles = value; }
        }
        #endregion Parameters

        #region Cmdlet Overrides
        /// <summary>
        /// The BeginProcessing method retrieves
        /// the current windows and the current processes.
        /// </summary>
        protected override void BeginProcessing()
        {
            // Retrieve the current windows.
            windowHandles = GetWindowsList.GetWindows();

            // Retrieve the current processes.
            processes = Process.GetProcesses();
        }

        /// <summary>
        /// The ProcessRecord method calls the Process.GetProcesses
        /// method to retrieve the processes specified by the Name
        /// parameter. Then, the WriteObject method writes the
        /// associated processes to the pipeline.
        /// </summary>
        protected override void ProcessRecord()
        {
            foreach (var windowHandle in windowHandles)
            {
                // Exclude hidden windows.
                if (!GetWindowsWin32.IsWindowVisible(windowHandle))
                {
                    continue;
                }

                // Get a length of a window title.
                int windowTltleLength = GetWindowsWin32.GetWindowTextLength(windowHandle);

                // Exclude windows without window titles.
                if (windowTltleLength == 0)
                {
                    continue;
                }

                // Get a window title.
                StringBuilder windowTitleBuilder = new StringBuilder(windowTltleLength + 1);
                GetWindowsWin32.GetWindowText(windowHandle, windowTitleBuilder, windowTitleBuilder.Capacity);
                String windowTitle = windowTitleBuilder.ToString();

                // Get a class name.
                StringBuilder windowClassNameBuilder = new StringBuilder(256);
                GetWindowsWin32.GetClassName(windowHandle, windowClassNameBuilder, windowClassNameBuilder.Capacity);
                String windowClassName = windowClassNameBuilder.ToString();

                // Get a process id.
                uint processId = 0;
                GetWindowsWin32.GetWindowThreadProcessId(windowHandle, out processId);

                // Get a process information.
                Process windowProcess = processes.FirstOrDefault(p => p.Id == processId);

                // Exclude windows without process information.
                if (windowProcess == null)
                {
                    continue;
                }


                // Try to retrive Process path from Process.MainModule.FileName.
                String windowProcessPath = "";

                try {
                    windowProcessPath = windowProcess.MainModule.FileName;
                }
                catch (Win32Exception e)
                {
                    // Ignore failed to access error.
                    if (e.ErrorCode == unchecked((int) 0x80004005)) // E_FAIL
                    {
                        WriteVerbose("Failed to access process \"" + windowProcess.ProcessName + "\".");
                    }
                    // Throw other errors.
                    else
                    {
                        throw;
                    }
                }

                // If the Id argument is provided,
                // exclude where Id isn't match the window process path.
                if (!checkArgument(Ids, processId))
                {
                    continue;
                }

                // If the ProcessPath argument is provided,
                // exclude where ProcessPath isn't match the window process path.
                if (!checkArgument(processPaths, windowProcessPath))
                {
                    continue;
                }

                // If the ProcessName argument is provided,
                // exclude where ProcessName isn't match the window process name.
                if (!checkArgument(processNames, windowProcess.ProcessName))
                {
                    continue;
                }

                // If the ClassName argument is provided,
                // exclude where ClassName isn't match the window className.
                if (!checkArgument(classNames, windowClassName))
                {
                    continue;
                }

                // If the WindowTitle argument is provided,
                // exclude where $WindowTitle isn't matched in the window title.
                if (!checkArgumentContains(windowTitles, windowTitle))
                {
                    continue;
                }

                // Add window information to the list. A little similar to Get-Process.
                GetWindowsResult result = new GetWindowsResult();
                result._Id                  = processId;
                result._ProcessName         = windowProcess.ProcessName;
                result._Path                = windowProcessPath;
                result._MainWindowHandle    = windowHandle.ToInt32();
                result._MainWindowTitle     = windowTitle;
                result._MainWindowClassName = windowClassName;

                // Write window information to the pipeline
                // to make them available to the next cmdlet.
                WriteObject(result);
            }
        }
        #endregion Cmdlet Overrides

        #region private functions
        /// <summary>
        /// This function compares a numeric array with a numeric value
        /// to determine whether there is a match.
        /// If the numeric array is empty,
        /// all numeric values are treated as "matching".
        /// </summary>
        private bool checkArgument(uint[] arguments, uint checkUint)
        {
            bool checkResult = false;

            if (arguments == null)
            {
                checkResult = true;
                return checkResult;
            }

            foreach (uint argument in arguments)
            {
                if (argument == checkUint)
                {
                    checkResult = true;
                    break;
                }
            }

            return checkResult;
        }

        /// <summary>
        /// This function compares a string array with a string
        /// to determine whether there is a match.
        /// If the string array is empty,
        /// all strings are treated as "matching".
        /// </summary>
        private bool checkArgument(string[] arguments, string checkString)
        {
            bool checkResult = false;

            if (arguments == null)
            {
                checkResult = true;
                return checkResult;
            }

            foreach (string argument in arguments)
            {
                if (argument == checkString)
                {
                    checkResult = true;
                    break;
                }
            }

            return checkResult;
        }

        /// <summary>
        /// This function compares a string array with a string
        /// to determine whether any strings partially match.
        /// If the string array is empty,
        /// all strings are treated as "matching".
        /// </summary>
        private bool checkArgumentContains(string[] arguments, string checkString)
        {
            bool checkResult = false;

            if (arguments == null)
            {
                checkResult = true;
                return checkResult;
            }

            foreach (string argument in arguments)
            {
                if (checkString.Contains(argument))
                {
                    checkResult = true;
                    break;
                }
            }

            return checkResult;
        }
        #endregion private functions
    }
    #endregion GetWindowsCommand

    #region GetWindowsResult
    /// <summary>
    /// This class implements the return value of the Get-Windows cmdlet.
    /// </summary>
    public class GetWindowsResult
    {
        #region Members
        internal uint   _Id;                  // Process.Id
        internal string _ProcessName;         // Process.ProcessName
        internal string _Path;                // Process.MainModule.FileName
        internal int    _MainWindowHandle;    // Process.MainWindowHandle
        internal string _MainWindowTitle;     // Process.MainWindowTitle
        internal string _MainWindowClassName;
        #endregion Members

        #region Properties
        public uint Id
        {
            get { return this._Id; }
        }

        public string Name
        {
            get { return this._ProcessName; }
        }

        public string ProcessName
        {
            get { return this._ProcessName; }
        }

        public string Path
        {
            get { return this._Path; }
        }

        public int MainWindowHandle
        {
            get { return this._MainWindowHandle; }
        }

        public string MainWindowTitle
        {
            get { return this._MainWindowTitle; }
        }

        public string MainWindowClassName
        {
            get { return this._MainWindowClassName; }
        }
        #endregion Properties

        #region Methods
        public override string ToString()
        {
            return "{Id=" + Id.ToString()
                + ", ProcessName=" + ProcessName
                + ", Path=" + Path
                + ", MainWindowHandle=" + MainWindowHandle.ToString()
                + ", MainWindowTitle=" + MainWindowTitle
                + ", MainWindowClassName=" + MainWindowClassName + "}";
        }
        #endregion Methods
    }
    #endregion Window

    #region GetWindowsWin32
    /// <summary>
    /// This class provides access to Win32 APIs.
    /// </summary>
    public static class GetWindowsWin32
    {
        // A callback function used with the EnumWindows function.
        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

        // Enumerates all top-level windows on the screen
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

        // Determines the visibility state of the specified window.
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool IsWindowVisible(IntPtr hWnd);

        // Retrieves the text of the specified window's title bar
        [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

        // Retrieves the length of the specified window's title bar text
        [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern int GetWindowTextLength(IntPtr hwnd);

        // Retrieves the name of the class to which the specified window belongs.
        [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);

        // Retrieves the identifier of the thread that created the specified window and the identifier of the process that created the window.
        [DllImport("user32.dll")]
        public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

        // Sets the show state of a window without waiting for the operation to complete.
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    }
    #endregion GetWindowsWin32

    #region GetWindowsList
    /// <summary>
    /// This class retrieves a list of main windows.
    /// </summary>
    internal class GetWindowsList
    {

        private GetWindowsList()
        {
            GetWindowsWin32.EnumWindows(callback, IntPtr.Zero);
        }

        private bool callback(IntPtr hWnd, IntPtr lparam)
        {
            _result.Add(hWnd);
            return true;
        }

        public static List<IntPtr> GetWindows()
        {
            return new GetWindowsList()._result;
        }

        private readonly List<IntPtr> _result = new List<IntPtr>();
    }
    #endregion GetWindowsList
"@ -PassThru

# Imports a cmdlet written in C# within a .ps1 file as a PowerShell module.
#
# .ps1ファイル内にC#で記述されたコマンドレットを、
# Powershellのモジュールとしてインポートします。
Import-Module -Assembly $CSData.Assembly -PassThru
