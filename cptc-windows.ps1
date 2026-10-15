#Requires -Version 5.1
<#
.SYNOPSIS
  Scope-bound Windows enumeration runner for authorized CPTC use.

.DESCRIPTION
  Installs selected tools, checks the workstation, runs local and network
  enumeration, and builds a static evidence report. Network actions are
  limited to the normalized IPv4 addresses supplied through -Target,
  -TargetsFile, or the legacy ranges/hosts fields in -ConfigPath.

.EXAMPLE
  .\cptc-windows.ps1 -Action Install -InstallTool Nmap,httpx,nuclei,ffuf -Verbose

.EXAMPLE
  .\cptc-windows.ps1 -Action Doctor -ConfigPath .\config.json -Verbose

.EXAMPLE
  .\cptc-windows.ps1 -Action Run -ConfigPath .\config.json -Profile Standard -AcknowledgeScope -Verbose

.EXAMPLE
  .\cptc-windows.ps1 -Action Report -RunDirectory .\cptc-results\20261014T180000Z_HOST_ab12cd34
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Alias('Mode')]
    [ValidateSet('Install', 'Doctor', 'Run', 'Report')]
    [string]$Action = 'Run',

    [Alias('Targets')]
    [string[]]$Target,

    [string]$TargetsFile,
    [string]$ConfigPath,
    [string[]]$Exclude,

    [Alias('Profile')]
    [ValidateSet('Quick', 'Standard', 'Deep')]
    [string]$ScanProfile = 'Standard',

    [string]$OutputDirectory = '.\cptc-results',
    [string]$RunDirectory,
    [string]$ToolsDirectory = '.\.cptc-tools\windows',
    [string]$NucleiTemplatesDirectory,

    [ValidateSet('Nmap', 'httpx', 'nuclei', 'ffuf')]
    [string[]]$InstallTool = @('Nmap', 'httpx', 'nuclei', 'ffuf'),

    [ValidateRange(1, 65536)]
    [int]$MaxTargets = 4096,

    [ValidateRange(1, 100000)]
    [int]$MaxRate = 1000,

    [ValidateRange(1, 256)]
    [int]$Throttle = 20,

    [ValidateRange(1, 1440)]
    [int]$HostTimeoutMinutes = 15,

    [ValidateRange(1, 86400)]
    [int]$CommandTimeoutSeconds = 3600,

    [ValidateRange(1, 1000)]
    [int]$WebRateLimit = 25,

    [ValidateRange(1, 1000000)]
    [int]$AdObjectLimit = 10000,

    [switch]$AllowPublicTargets,
    [switch]$AcknowledgeScope,
    [switch]$NonInteractive,
    [switch]$EnableUdp,
    [switch]$EnableAd,
    [string]$AuthorizedAdDomain,
    [switch]$AcknowledgeAdDomain,
    [switch]$EnableNuclei,
    [switch]$EnableFfuf,
    [string]$Wordlist,
    [switch]$SkipLocalInventory,
    [switch]$SkipWeb,
    [switch]$Resume,
    [switch]$Force
)

if ($ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') {
    throw ("cptc-windows.ps1 requires PowerShell FullLanguage mode; the current session is {0}. Run it from an authorized workstation/session where application-control policy permits FullLanguage mode." -f
        $ExecutionContext.SessionState.LanguageMode)
}

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$script:ScriptPath = $MyInvocation.MyCommand.Path
$script:RootCmdlet = $PSCmdlet
$script:RunRoot = $null
$script:LogDirectory = $null
$script:RawDirectory = $null
$script:NormalizedDirectory = $null
$script:ReportDirectory = $null
$script:ScopeDirectory = $null
$script:RunnerLog = $null
$script:EventLog = $null
$script:TranscriptPath = $null
$script:ManifestPath = $null
$script:TranscriptStarted = $false
$script:CommandCounter = 0
$script:HadErrors = $false
$script:ErrorCount = 0
$script:CollectorFailureCount = 0
$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$script:Utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)
$script:Manifest = $null
$script:ToolCache = @{}
$script:ResumeScopeMatches = $false
$script:OriginalScopeSha256 = $null
$script:OriginalScopeCount = $null
$script:OriginalResolutionMapSha256 = $null
$script:OriginalResolutionMapJson = $null
$script:OriginalNmapDataManifestSha256 = $null
$script:OriginalNmapDataTreeSha256 = $null
$script:OriginalNmapDataDirectory = $null
$script:OriginalNmapExecutableSha256 = $null
$script:NmapDataBaseline = $null
$script:NmapDataIntegrityFailed = $false
$script:NmapProcessIsolation = $null
$script:BinaryProvenanceCache = @{}
$script:ExistingChecksumStatus = 'not-checked'
$script:CheckpointIntegrityVerified = $false
$script:EvidenceIntegrityFailure = $false
$script:SuppressArtifactHashFinalization = $false
$script:ChecksumVerificationIssues = @()
$script:RunLockStream = $null
$script:ToolInstallLockStream = $null

if (-not ('CptcProcessCapture' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading;

public sealed class CptcProcessCapture
{
    public readonly BlockingCollection<string> Stdout;
    public readonly BlockingCollection<string> Stderr;
    private readonly StreamWriter stdoutWriter;
    private readonly StreamWriter stderrWriter;
    private readonly object stdoutGate = new object();
    private readonly object stderrGate = new object();
    private readonly object errorGate = new object();
    private long droppedStdout;
    private long droppedStderr;
    private int completed;
    private string captureError;

    public CptcProcessCapture(string stdoutPath, string stderrPath, int queueCapacity)
    {
        Stdout = new BlockingCollection<string>(new ConcurrentQueue<string>(), queueCapacity);
        Stderr = new BlockingCollection<string>(new ConcurrentQueue<string>(), queueCapacity);
        stdoutWriter = new StreamWriter(stdoutPath, false, new UTF8Encoding(false));
        stderrWriter = new StreamWriter(stderrPath, false, new UTF8Encoding(false));
        stdoutWriter.AutoFlush = true;
        stderrWriter.AutoFlush = true;
    }

    public long DroppedStdout { get { return Interlocked.Read(ref droppedStdout); } }
    public long DroppedStderr { get { return Interlocked.Read(ref droppedStderr); } }
    public string CaptureError { get { lock (errorGate) { return captureError; } } }

    private void RecordError(Exception exception)
    {
        lock (errorGate)
        {
            if (captureError == null) { captureError = exception.ToString(); }
        }
    }

    private void Publish(BlockingCollection<string> queue, string value, ref long dropped)
    {
        try
        {
            if (!queue.TryAdd(value)) { Interlocked.Increment(ref dropped); }
        }
        catch (InvalidOperationException)
        {
            Interlocked.Increment(ref dropped);
        }
    }

    public void Attach(Process process)
    {
        process.OutputDataReceived += delegate(object sender, DataReceivedEventArgs args)
        {
            if (args.Data == null) { return; }
            try { lock (stdoutGate) { stdoutWriter.WriteLine(args.Data); } }
            catch (Exception exception) { RecordError(exception); }
            Publish(Stdout, args.Data, ref droppedStdout);
        };
        process.ErrorDataReceived += delegate(object sender, DataReceivedEventArgs args)
        {
            if (args.Data == null) { return; }
            try { lock (stderrGate) { stderrWriter.WriteLine(args.Data); } }
            catch (Exception exception) { RecordError(exception); }
            Publish(Stderr, args.Data, ref droppedStderr);
        };
    }

    public void Complete()
    {
        if (Interlocked.Exchange(ref completed, 1) != 0) { return; }
        Stdout.CompleteAdding();
        Stderr.CompleteAdding();
        lock (stdoutGate) { stdoutWriter.Dispose(); }
        lock (stderrGate) { stderrWriter.Dispose(); }
    }
}
'@
}

function Get-FullPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    if ([IO.Path]::IsPathRooted($Path)) {
        return [IO.Path]::GetFullPath($Path)
    }
    return [IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}

function Enter-ExclusiveFileLock {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Purpose
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }
    try {
        $stream = [IO.File]::Open($Path, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    }
    catch {
        throw "Could not acquire the $Purpose lock at $Path. Another runner may be using it: $($_.Exception.Message)"
    }
    try {
        $metadata = [ordered]@{
            purpose = $Purpose
            processId = $PID
            action = $Action
            computerName = $env:COMPUTERNAME
            acquiredUtc = [DateTime]::UtcNow.ToString('o')
        } | ConvertTo-Json -Compress
        $bytes = $script:Utf8NoBom.GetBytes($metadata + [Environment]::NewLine)
        $stream.SetLength(0)
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush()
        return $stream
    }
    catch {
        $stream.Dispose()
        throw
    }
}

function Enter-SharedFileLock {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Purpose
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        try {
            $createStream = [IO.File]::Open($Path, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::Write, [IO.FileShare]::ReadWrite)
            $createStream.Dispose()
        }
        catch {
            throw "Could not initialize the $Purpose lock at $Path`: $($_.Exception.Message)"
        }
    }
    try {
        return [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
    }
    catch {
        throw "Could not acquire the shared $Purpose lock at $Path. A tool installation may be replacing managed binaries or templates: $($_.Exception.Message)"
    }
}

function Write-Utf8File {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [AllowEmptyString()][string]$Content
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }
    [IO.File]::WriteAllText($Path, $Content, $script:Utf8NoBom)
}

function Read-Utf8File {
    param([Parameter(Mandatory = $true)][string]$Path)
    # File.ReadAllText uses a BOM-aware StreamReader internally.  Supplying a
    # strict UTF-8 decoder also prevents Windows PowerShell 5.1 from silently
    # treating our BOM-less evidence files as the active ANSI code page.
    return [IO.File]::ReadAllText($Path, $script:Utf8Strict)
}

function Read-Utf8Lines {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [IO.File]::ReadLines($Path, $script:Utf8Strict)
}

function Add-Utf8Line {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [AllowEmptyString()][string]$Content
    )
    [IO.File]::AppendAllText($Path, $Content + [Environment]::NewLine, $script:Utf8NoBom)
}

function Get-TextSha256 {
    param([AllowEmptyString()][string]$Content)
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = $script:Utf8NoBom.GetBytes($Content)
        return ([BitConverter]::ToString($sha256.ComputeHash($bytes))).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
    }
}

function Write-Log {
    param(
        [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO',
        [Parameter(Mandatory = $true)][string]$Message
    )
    $timestamp = [DateTime]::UtcNow.ToString('o')
    $line = '[{0}] [{1}] {2}' -f $timestamp, $Level, $Message
    if ($script:RunnerLog) {
        Add-Utf8Line -Path $script:RunnerLog -Content $line
    }
    switch ($Level) {
        'DEBUG' { Write-Verbose $Message }
        'WARN' { Write-Warning $Message }
        'ERROR' {
            $script:HadErrors = $true
            $script:ErrorCount++
            Write-Host $line -ForegroundColor Red
        }
        'SUCCESS' { Write-Host $line -ForegroundColor Green }
        default { Write-Host $line }
    }
}

function Get-IsAdministrator {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function Get-SafeName {
    param([Parameter(Mandatory = $true)][string]$Value)
    return ($Value -replace '[^A-Za-z0-9_.-]', '_')
}

function ConvertTo-WindowsCommandLineArgument {
    param([AllowEmptyString()][string]$Argument)
    if ($null -eq $Argument -or $Argument.Length -eq 0) {
        return '""'
    }
    if ($Argument -notmatch '[\s"]') {
        return $Argument
    }

    $builder = New-Object System.Text.StringBuilder
    [void]$builder.Append([char]34)
    $backslashes = 0
    for ($index = 0; $index -lt $Argument.Length; $index++) {
        $character = $Argument[$index]
        if ($character -eq [char]92) {
            $backslashes++
            continue
        }
        if ($character -eq [char]34) {
            if ($backslashes -gt 0) {
                [void]$builder.Append([char]92, (2 * $backslashes))
            }
            [void]$builder.Append([char]92)
            [void]$builder.Append([char]34)
            $backslashes = 0
            continue
        }
        if ($backslashes -gt 0) {
            [void]$builder.Append([char]92, $backslashes)
            $backslashes = 0
        }
        [void]$builder.Append($character)
    }
    if ($backslashes -gt 0) {
        [void]$builder.Append([char]92, (2 * $backslashes))
    }
    [void]$builder.Append([char]34)
    return $builder.ToString()
}

function Get-RedactedArguments {
    param([string[]]$ArgumentList)
    $redacted = New-Object System.Collections.Generic.List[System.String]
    $maskNext = $false
    foreach ($argument in @($ArgumentList)) {
        if ($maskNext) {
            [void]$redacted.Add('<redacted>')
            $maskNext = $false
            continue
        }
        if ($argument -match '^(?i:--?(password|passwd|token|api-key|apikey|secret|community|authorization))$') {
            [void]$redacted.Add($argument)
            $maskNext = $true
            continue
        }
        $safe = $argument -replace '(?i)((password|passwd|token|api[_-]?key|secret|community|authorization)=)[^\s]+', '$1<redacted>'
        [void]$redacted.Add($safe)
    }
    return $redacted.ToArray()
}

function Get-ToolCacheKey {
    param([Parameter(Mandatory = $true)][string]$Name)
    return [IO.Path]::GetFileNameWithoutExtension($Name).ToLowerInvariant()
}

function Get-ManagedToolCandidateMetadata {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ExpectedName,
        [switch]$Quiet
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    $toolsRoot = [IO.Path]::GetFullPath($ToolsDirectory).TrimEnd([char[]]@('\', '/'))
    $candidatePath = [IO.Path]::GetFullPath($Path)
    $rootPrefix = $toolsRoot + [IO.Path]::DirectorySeparatorChar
    if (-not $candidatePath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) { return $null }

    $directory = (Get-Item -LiteralPath $candidatePath).Directory
    $manifestPath = $null
    while ($directory -and $directory.FullName.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        $candidateManifest = Join-Path $directory.FullName 'install-manifest.json'
        if (Test-Path -LiteralPath $candidateManifest -PathType Leaf) {
            $manifestPath = $candidateManifest
            break
        }
        $directory = $directory.Parent
    }
    if (-not $manifestPath) {
        if (-not $Quiet) { Write-Log -Level WARN -Message ("Ignoring unmanaged executable under the tools directory: {0}" -f $candidatePath) }
        return $null
    }

    try {
        $installManifest = (Read-Utf8File -Path $manifestPath) | ConvertFrom-Json
        $expectedHash = [string]$installManifest.executableSha256
        $manifestName = Get-ToolCacheKey -Name ([string]$installManifest.name)
        $expectedKey = Get-ToolCacheKey -Name $ExpectedName
        $installedUtc = [DateTime]::MinValue
        if (-not $expectedHash -or $expectedHash -notmatch '^[A-Fa-f0-9]{64}$') {
            throw 'the install manifest has no valid executableSha256'
        }
        if ($manifestName -ne $expectedKey) {
            throw ("the install manifest names {0}, expected {1}" -f $manifestName, $expectedKey)
        }
        if (-not [DateTime]::TryParse(
                [string]$installManifest.installedUtc,
                [Globalization.CultureInfo]::InvariantCulture,
                [Globalization.DateTimeStyles]::RoundtripKind,
                [ref]$installedUtc)) {
            throw 'the install manifest has no valid installedUtc timestamp'
        }
        $actualHash = (Get-FileHash -LiteralPath $candidatePath -Algorithm SHA256).Hash
        if ($actualHash -ine $expectedHash) {
            throw ("executable SHA-256 mismatch (expected {0}, received {1})" -f $expectedHash, $actualHash)
        }
        return [pscustomobject]@{
            Path = $candidatePath
            ManifestPath = $manifestPath
            InstalledUtc = $installedUtc.ToUniversalTime()
            Release = [string]$installManifest.release
            Sha256 = $actualHash.ToUpperInvariant()
        }
    }
    catch {
        if (-not $Quiet) { Write-Log -Level WARN -Message ("Ignoring managed tool candidate {0}: {1}" -f $candidatePath, $_.Exception.Message) }
        return $null
    }
}

function Test-ManagedToolCandidate {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ExpectedName,
        [switch]$Quiet
    )
    return $null -ne (Get-ManagedToolCandidateMetadata -Path $Path -ExpectedName $ExpectedName -Quiet:$Quiet)
}

function Find-Tool {
    param([Parameter(Mandatory = $true)][string]$Name)
    $cacheKey = Get-ToolCacheKey -Name $Name
    if ($script:ToolCache.ContainsKey($cacheKey)) {
        $cached = $script:ToolCache[$cacheKey]
        if ($cached -and (Test-Path -LiteralPath $cached -PathType Leaf)) {
            $toolsRoot = [IO.Path]::GetFullPath($ToolsDirectory).TrimEnd([char[]]@('\', '/'))
            $cachedFullPath = [IO.Path]::GetFullPath($cached)
            if (-not $cachedFullPath.StartsWith(($toolsRoot + [IO.Path]::DirectorySeparatorChar), [StringComparison]::OrdinalIgnoreCase) -or
                (Test-ManagedToolCandidate -Path $cachedFullPath -ExpectedName $Name)) {
                return $cachedFullPath
            }
        }
        [void]$script:ToolCache.Remove($cacheKey)
    }

    $leaf = $Name
    if (-not $leaf.EndsWith('.exe', [StringComparison]::OrdinalIgnoreCase)) {
        $leaf += '.exe'
    }
    if (Test-Path -LiteralPath $ToolsDirectory -PathType Container) {
        $validatedCandidates = New-Object System.Collections.Generic.List[System.Object]
        foreach ($managedCandidate in @(Get-ChildItem -LiteralPath $ToolsDirectory -Filter $leaf -File -Recurse -ErrorAction SilentlyContinue)) {
            $metadata = Get-ManagedToolCandidateMetadata -Path $managedCandidate.FullName -ExpectedName $Name
            if ($metadata) { [void]$validatedCandidates.Add($metadata) }
        }
        $managedSortProperties = @(
            @{ Expression = { $_.InstalledUtc }; Descending = $true }
            @{ Expression = { $_.Release }; Descending = $true }
            @{ Expression = { $_.Path }; Descending = $false }
        )
        $selectedCandidate = @($validatedCandidates.ToArray() | Sort-Object -Property $managedSortProperties | Select-Object -First 1)
        if ($selectedCandidate.Count -gt 0) {
            $script:ToolCache[$cacheKey] = $selectedCandidate[0].Path
            return $selectedCandidate[0].Path
        }
    }

    $commandNames = New-Object System.Collections.Generic.List[System.String]
    [void]$commandNames.Add($Name)
    if ($Name.EndsWith('.exe', [StringComparison]::OrdinalIgnoreCase)) {
        [void]$commandNames.Add([IO.Path]::GetFileNameWithoutExtension($Name))
    }
    $toolsRoot = [IO.Path]::GetFullPath($ToolsDirectory).TrimEnd([char[]]@('\', '/'))
    $rootPrefix = $toolsRoot + [IO.Path]::DirectorySeparatorChar
    foreach ($commandName in @($commandNames.ToArray() | Select-Object -Unique)) {
        foreach ($command in @(Get-Command $commandName -CommandType Application -All -ErrorAction SilentlyContinue)) {
            $path = $command.Source
            if (-not $path) { $path = $command.Path }
            if (-not $path) { continue }
            $fullCommandPath = [IO.Path]::GetFullPath($path)
            if ($fullCommandPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -and
                -not (Test-ManagedToolCandidate -Path $fullCommandPath -ExpectedName $Name)) {
                continue
            }
            $script:ToolCache[$cacheKey] = $fullCommandPath
            return $fullCommandPath
        }
    }

    $candidates = New-Object System.Collections.Generic.List[System.String]
    if ($Name -match '^(?i:nmap(?:\.exe)?)$') {
        if (${env:ProgramFiles(x86)}) {
            [void]$candidates.Add((Join-Path ${env:ProgramFiles(x86)} 'Nmap\nmap.exe'))
        }
        if ($env:ProgramFiles) {
            [void]$candidates.Add((Join-Path $env:ProgramFiles 'Nmap\nmap.exe'))
        }
    }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $script:ToolCache[$cacheKey] = $candidate
            return $candidate
        }
    }
    return $null
}

function Write-ProcessQueue {
    param(
        [Parameter(Mandatory = $true)]$Queue,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][ValidateSet('stdout', 'stderr')][string]$Stream,
        [ValidateRange(1, 8192)][int]$MaxLines = 256
    )
    $line = $null
    $written = 0
    while ($written -lt $MaxLines -and $Queue.TryTake([ref]$line)) {
        Write-Verbose ("[{0} {1}] {2}" -f $Name, $Stream, [string]$line)
        $written++
        $line = $null
    }
    return $written
}

function Read-BoundedProcessLog {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [int]$MaxBytes = 1048576
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    $fileInfo = Get-Item -LiteralPath $Path
    if ($fileInfo.Length -le $MaxBytes) { return [string](Read-Utf8File -Path $Path) }
    $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
    try {
        [void]$stream.Seek(-[int64]$MaxBytes, [IO.SeekOrigin]::End)
        $buffer = New-Object byte[] $MaxBytes
        $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
        $tail = $script:Utf8NoBom.GetString($buffer, 0, $bytesRead)
        return ("[in-memory output truncated; complete log: {0}]`n{1}" -f $Path, $tail)
    }
    finally {
        $stream.Dispose()
    }
}

function Record-ExecutedBinary {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$CommandName
    )
    $fullPath = [IO.Path]::GetFullPath($Path)
    $file = Get-Item -LiteralPath $fullPath -ErrorAction Stop
    if ($file.PSIsContainer) { throw "Executable path is not a file: $fullPath" }
    $fingerprint = '{0}|{1}' -f $file.Length, $file.LastWriteTimeUtc.Ticks
    $cacheEntry = if ($script:BinaryProvenanceCache.ContainsKey($fullPath)) { $script:BinaryProvenanceCache[$fullPath] } else { $null }
    if (-not $cacheEntry -or $cacheEntry.Fingerprint -ne $fingerprint) {
        $cacheEntry = [pscustomobject]@{
            Fingerprint = $fingerprint
            Sha256 = (Get-FileHash -LiteralPath $fullPath -Algorithm SHA256).Hash.ToUpperInvariant()
            Length = [int64]$file.Length
            LastWriteUtc = $file.LastWriteTimeUtc.ToString('o')
        }
        $script:BinaryProvenanceCache[$fullPath] = $cacheEntry
    }
    if ($script:Manifest) {
        if (-not $script:Manifest.Contains('executedBinaries') -or -not $script:Manifest.executedBinaries) {
            $script:Manifest.executedBinaries = [ordered]@{}
        }
        $recordKey = (Get-TextSha256 -Content $fullPath.ToLowerInvariant()).Substring(0, 24)
        $existing = $script:Manifest.executedBinaries[$recordKey]
        $now = [DateTime]::UtcNow.ToString('o')
        if ($existing) {
            $existing.sha256 = $cacheEntry.Sha256
            $existing.fileSize = $cacheEntry.Length
            $existing.lastWriteUtc = $cacheEntry.LastWriteUtc
            $existing.lastExecutedUtc = $now
            $existing.invocationCount = [int]$existing.invocationCount + 1
            $existing.commandNames = @(@($existing.commandNames) + $CommandName | Select-Object -Unique)
        }
        else {
            $script:Manifest.executedBinaries[$recordKey] = [ordered]@{
                path = $fullPath
                sha256 = $cacheEntry.Sha256
                fileSize = $cacheEntry.Length
                lastWriteUtc = $cacheEntry.LastWriteUtc
                firstExecutedUtc = $now
                lastExecutedUtc = $now
                invocationCount = 1
                commandNames = @($CommandName)
            }
        }
        Write-RunManifest
    }
    return $cacheEntry.Sha256
}

function Invoke-LoggedProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$ArgumentList = @(),
        [Parameter(Mandatory = $true)][string]$Name,
        [int]$TimeoutSeconds = $CommandTimeoutSeconds,
        [int[]]$AllowedExitCodes = @(0),
        [switch]$ContinueOnError,
        [string]$WorkingDirectory,
        [string[]]$ClearEnvironmentVariables = @(),
        [hashtable]$EnvironmentOverrides = @{}
    )

    $resolvedPath = $FilePath
    if (-not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)) {
        $tool = Get-Command $FilePath -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $tool) { throw "Executable not found: $FilePath" }
        $resolvedPath = $tool.Source
        if (-not $resolvedPath) { $resolvedPath = $tool.Path }
    }

    $script:CommandCounter++
    $safeName = Get-SafeName -Value $Name
    $prefix = '{0:D3}_{1}' -f $script:CommandCounter, $safeName
    $stdoutPath = Join-Path $script:LogDirectory ($prefix + '.stdout.log')
    $stderrPath = Join-Path $script:LogDirectory ($prefix + '.stderr.log')
    $redactedArguments = @(Get-RedactedArguments -ArgumentList $ArgumentList)
    $clearedEnvironmentNames = @($ClearEnvironmentVariables | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    $overriddenEnvironmentNames = @($EnvironmentOverrides.Keys | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
    $displayParts = @((ConvertTo-WindowsCommandLineArgument -Argument $resolvedPath))
    $displayParts += @($redactedArguments | ForEach-Object { ConvertTo-WindowsCommandLineArgument -Argument $_ })
    $displayCommand = $displayParts -join ' '
    $executableSha256 = Record-ExecutedBinary -Path $resolvedPath -CommandName $Name
    Write-Log -Level INFO -Message ("Starting {0}: {1}" -f $Name, $displayCommand)

    $start = [DateTime]::UtcNow
    $timedOut = $false
    $exitCode = -1
    $processId = $null
    $stdout = ''
    $stderr = ''
    $process = $null
    $capture = $null
    $processStarted = $false
    $processFailureText = $null
    $captureErrorText = $null
    $droppedStdoutLines = 0
    $droppedStderrLines = 0
    Write-Utf8File -Path $stdoutPath -Content ''
    Write-Utf8File -Path $stderrPath -Content ''
    try {
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $resolvedPath
        $startInfo.Arguments = (@($ArgumentList | ForEach-Object { ConvertTo-WindowsCommandLineArgument -Argument $_ }) -join ' ')
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        if ($WorkingDirectory) { $startInfo.WorkingDirectory = $WorkingDirectory }
        foreach ($environmentName in $clearedEnvironmentNames) {
            if ($startInfo.EnvironmentVariables.ContainsKey($environmentName)) {
                $startInfo.EnvironmentVariables.Remove($environmentName)
            }
        }
        foreach ($environmentName in $overriddenEnvironmentNames) {
            $startInfo.EnvironmentVariables[$environmentName] = [string]$EnvironmentOverrides[$environmentName]
        }

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo
        $capture = New-Object CptcProcessCapture -ArgumentList @($stdoutPath, $stderrPath, 8192)
        $capture.Attach($process)
        if (-not $process.Start()) { throw "Failed to start $resolvedPath" }
        $processStarted = $true
        $processId = $process.Id
        $process.BeginOutputReadLine()
        $process.BeginErrorReadLine()
        $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
        while (-not $process.WaitForExit(250)) {
            [void](Write-ProcessQueue -Queue $capture.Stdout -Name $Name -Stream stdout)
            [void](Write-ProcessQueue -Queue $capture.Stderr -Name $Name -Stream stderr)
            if ([DateTime]::UtcNow -ge $deadline) {
                $timedOut = $true
                Write-Log -Level WARN -Message ("{0} timed out after {1} seconds; stopping PID {2}." -f $Name, $TimeoutSeconds, $processId)
                try {
                    $taskKill = if ($env:SystemRoot) { Join-Path $env:SystemRoot 'System32\taskkill.exe' } else { $null }
                    if ($taskKill -and (Test-Path -LiteralPath $taskKill)) {
                        & $taskKill /PID $processId /T /F 2>&1 | Out-Null
                    }
                    else {
                        $process.Kill()
                    }
                }
                catch {
                    Write-Log -Level WARN -Message ("Could not stop PID {0}: {1}" -f $processId, $_.Exception.Message)
                }
                break
            }
        }
        if (-not $process.HasExited) { [void]$process.WaitForExit(10000) }
        if ($process.HasExited) {
            # Parameterless WaitForExit also waits for asynchronous output callbacks to finish.
            $process.WaitForExit()
            $exitCode = $process.ExitCode
        }
        else {
            $processFailureText = 'The process did not exit after its timeout and termination attempt.'
        }
    }
    catch {
        $processFailureText = $_.Exception.ToString()
        Write-Log -Level ERROR -Message ("Failed to run {0}: {1}" -f $Name, $_.Exception.Message)
    }
    finally {
        if ($processStarted -and $process -and -not $process.HasExited) {
            try { $process.Kill() } catch { }
            try { [void]$process.WaitForExit(5000) } catch { }
        }
        if ($processStarted -and $process -and -not $process.HasExited) {
            try { $process.CancelOutputRead() } catch { }
            try { $process.CancelErrorRead() } catch { }
        }
        if ($capture) {
            try { $capture.Complete() } catch { if (-not $processFailureText) { $processFailureText = $_.Exception.ToString() } }
            while ((Write-ProcessQueue -Queue $capture.Stdout -Name $Name -Stream stdout -MaxLines 8192) -gt 0) { }
            while ((Write-ProcessQueue -Queue $capture.Stderr -Name $Name -Stream stderr -MaxLines 8192) -gt 0) { }
            $droppedStdoutLines = [int64]$capture.DroppedStdout
            $droppedStderrLines = [int64]$capture.DroppedStderr
            if ($droppedStdoutLines -gt 0 -or $droppedStderrLines -gt 0) {
                Write-Log -Level WARN -Message ("Verbose console output for {0} omitted {1} stdout and {2} stderr line(s) under sustained output; complete output remains in the per-command disk logs." -f
                    $Name, $droppedStdoutLines, $droppedStderrLines)
            }
            if ($capture.CaptureError) {
                $captureErrorText = [string]$capture.CaptureError
                $processFailureText = ("Process log capture error: {0}`n{1}" -f $captureErrorText, $processFailureText).Trim()
            }
        }
        if ($process) { try { $process.Dispose() } catch { } }
        if ($processFailureText) { Add-Utf8Line -Path $stderrPath -Content $processFailureText }
    }

    $stdout = Read-BoundedProcessLog -Path $stdoutPath
    $stderr = Read-BoundedProcessLog -Path $stderrPath

    $end = [DateTime]::UtcNow
    $success = (-not $timedOut) -and (-not $captureErrorText) -and (-not $processFailureText) -and ($AllowedExitCodes -contains $exitCode)
    $eventProcessError = if ($processFailureText -and $processFailureText.Length -gt 8192) {
        $processFailureText.Substring(0, 8192) + '[truncated]'
    }
    else {
        $processFailureText
    }
    $processEvent = [ordered]@{
        timestampUtc = $start.ToString('o')
        completedUtc = $end.ToString('o')
        durationSeconds = [Math]::Round(($end - $start).TotalSeconds, 3)
        name = $Name
        executable = $resolvedPath
        executableSha256 = $executableSha256
        arguments = $redactedArguments
        workingDirectory = $WorkingDirectory
        clearedEnvironmentVariables = $clearedEnvironmentNames
        overriddenEnvironmentVariables = $overriddenEnvironmentNames
        pid = $processId
        exitCode = $exitCode
        timedOut = $timedOut
        captureError = $captureErrorText
        processError = $eventProcessError
        droppedVerboseStdoutLines = $droppedStdoutLines
        droppedVerboseStderrLines = $droppedStderrLines
        success = $success
        stdout = $stdoutPath
        stderr = $stderrPath
    }
    Add-Utf8Line -Path $script:EventLog -Content ($processEvent | ConvertTo-Json -Depth 6 -Compress)

    if ($success) {
        Write-Log -Level SUCCESS -Message ("Completed {0} with exit code {1} in {2:n1}s." -f $Name, $exitCode, ($end - $start).TotalSeconds)
    }
    else {
        $script:HadErrors = $true
        $message = "{0} failed with exit code {1}{2}. See {3}" -f $Name, $exitCode, $(if ($timedOut) { ' (timeout)' } else { '' }), $stderrPath
        if ($ContinueOnError) {
            Write-Log -Level ERROR -Message $message
        }
        else {
            throw $message
        }
    }
    return [pscustomobject]@{
        Success = $success
        ExitCode = $exitCode
        TimedOut = $timedOut
        Stdout = $stdout
        Stderr = $stderr
        StdoutPath = $stdoutPath
        StderrPath = $stderrPath
    }
}

function Get-FileByteSnapshot {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required evidence file does not exist: $Path"
    }
    $bytes = [IO.File]::ReadAllBytes($Path)
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = ([BitConverter]::ToString($sha256.ComputeHash($bytes))).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
    }
    return [pscustomobject]@{
        Path = $Path
        Sha256 = $hash
        Text = $script:Utf8Strict.GetString($bytes)
    }
}

function Assert-OriginalResumeScopeIntegrity {
    if (-not $Resume) { return $null }
    if ($script:OriginalScopeSha256 -notmatch '^[A-Fa-f0-9]{64}$' -or
        $null -eq $script:OriginalScopeCount -or $script:OriginalScopeCount -lt 1 -or
        $script:OriginalResolutionMapSha256 -notmatch '^[A-Fa-f0-9]{64}$') {
        throw 'The original run manifest lacks complete scope integrity metadata; refusing Resume.'
    }

    $targetPath = Join-Path $script:ScopeDirectory 'targets.txt'
    $targetSnapshot = Get-FileByteSnapshot -Path $targetPath
    if ($targetSnapshot.Sha256 -ine $script:OriginalScopeSha256) {
        throw ("Resume scope integrity failure: {0} has SHA-256 {1}, but the original run manifest records {2}. No checkpoint will be reused." -f
            $targetPath, $targetSnapshot.Sha256, $script:OriginalScopeSha256)
    }
    $validatedTargets = New-Object System.Collections.Generic.List[System.String]
    $seenTargets = New-Object -TypeName 'System.Collections.Generic.HashSet[System.String]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($line in @($targetSnapshot.Text -split "`r`n|`n|`r")) {
        $candidate = ([string]$line).Trim()
        if (-not $candidate) { continue }
        $parsedAddress = $null
        if (-not [Net.IPAddress]::TryParse($candidate, [ref]$parsedAddress) -or
            $parsedAddress.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork) {
            throw "Resume scope integrity failure: the original frozen scope contains an invalid IPv4 entry: $candidate"
        }
        $normalizedAddress = $parsedAddress.ToString()
        if (-not $seenTargets.Add($normalizedAddress)) {
            throw "Resume scope integrity failure: the original frozen scope contains duplicate address $normalizedAddress."
        }
        [void]$validatedTargets.Add($normalizedAddress)
    }
    if ($validatedTargets.Count -ne $script:OriginalScopeCount) {
        throw ("Resume scope integrity failure: {0} contains {1} target(s), but the original run manifest records {2}. No checkpoint will be reused." -f
            $targetPath, $validatedTargets.Count, $script:OriginalScopeCount)
    }

    $resolutionMapPath = Join-Path $script:ScopeDirectory 'resolution-map.json'
    $resolutionSnapshot = Get-FileByteSnapshot -Path $resolutionMapPath
    if ($resolutionSnapshot.Sha256 -ine $script:OriginalResolutionMapSha256) {
        throw ("Resume resolution-map integrity failure: {0} has SHA-256 {1}, but the original run manifest records {2}. No hostname follow-up or checkpoint will be reused." -f
            $resolutionMapPath, $resolutionSnapshot.Sha256, $script:OriginalResolutionMapSha256)
    }
    try {
        [void]($resolutionSnapshot.Text | ConvertFrom-Json)
    }
    catch {
        throw "Resume resolution-map integrity failure: the hash-bound file is not valid JSON: $($_.Exception.Message)"
    }
    $script:OriginalResolutionMapJson = $resolutionSnapshot.Text
    Write-Log -Level INFO -Message ("Validated original Resume scope ({0} target(s), SHA-256 {1}) and resolution map (SHA-256 {2})." -f
        $validatedTargets.Count, $targetSnapshot.Sha256, $resolutionSnapshot.Sha256)
    return [pscustomobject]@{
        Targets = $validatedTargets.ToArray()
        TargetSha256 = $targetSnapshot.Sha256
        ResolutionMapSha256 = $resolutionSnapshot.Sha256
    }
}

function Initialize-RunContext {
    param([switch]$UseExisting)
    # The root cmdlet owns the externally visible ShouldProcess gates.  Its
    # -WhatIf preference must not suppress private state, evidence directories,
    # locks, or logs needed to explain what the gated action would do.
    $WhatIfPreference = $false
    if ($Resume -and $Action -ne 'Run') {
        throw '-Resume is valid only with -Action Run.'
    }
    if ($Action -eq 'Run' -and $Resume -and [string]::IsNullOrWhiteSpace($RunDirectory)) {
        throw '-RunDirectory is required with -Resume so checkpoint reuse cannot select the wrong run.'
    }
    $outputRoot = Get-FullPath -Path $OutputDirectory
    $toolsRoot = Get-FullPath -Path $ToolsDirectory
    $script:ToolCache.Clear()
    $script:ToolsDirectory = $toolsRoot
    $templatesRoot = if ([string]::IsNullOrWhiteSpace($NucleiTemplatesDirectory)) {
        Join-Path $toolsRoot 'nuclei-templates'
    }
    else {
        Get-FullPath -Path $NucleiTemplatesDirectory
    }
    $script:NucleiTemplatesDirectory = $templatesRoot
    if (-not (Test-Path -LiteralPath $outputRoot)) {
        [void](New-Item -ItemType Directory -Path $outputRoot -Force)
    }

    if ($UseExisting) {
        if ($RunDirectory) {
            $script:RunRoot = Get-FullPath -Path $RunDirectory
        }
        else {
            $candidateRuns = Get-ChildItem -LiteralPath $outputRoot -Directory -ErrorAction SilentlyContinue |
                Where-Object {
                    $linkTypeProperty = $_.PSObject.Properties['LinkType']
                    $isLink = $linkTypeProperty -and -not [string]::IsNullOrWhiteSpace([string]$linkTypeProperty.Value)
                    -not $isLink -and
                    (($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) -and
                    $_.Name -ine '.cptc-unverified-resume' -and
                    (Test-Path -LiteralPath (Join-Path $_.FullName 'run-manifest.json') -PathType Leaf) -and
                    (Test-Path -LiteralPath (Join-Path $_.FullName 'logs') -PathType Container) -and
                    (Test-Path -LiteralPath (Join-Path $_.FullName 'raw') -PathType Container) -and
                    (Test-Path -LiteralPath (Join-Path $_.FullName 'normalized') -PathType Container) -and
                    (Test-Path -LiteralPath (Join-Path $_.FullName 'report') -PathType Container) -and
                    (Test-Path -LiteralPath (Join-Path $_.FullName 'scope') -PathType Container)
                } |
                Sort-Object LastWriteTimeUtc -Descending
            if ($Action -eq 'Run' -and $Resume) {
                $candidateRuns = @($candidateRuns | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'scope\targets.txt') })
            }
            $latest = $candidateRuns | Select-Object -First 1
            if (-not $latest) { throw "No run directories were found under $outputRoot." }
            $script:RunRoot = $latest.FullName
        }
        if (-not (Test-Path -LiteralPath $script:RunRoot -PathType Container)) {
            throw "Run directory does not exist: $($script:RunRoot)"
        }
        if ($Action -eq 'Run' -and $Resume) {
            $originalManifestPath = Join-Path $script:RunRoot 'run-manifest.json'
            if (-not (Test-Path -LiteralPath $originalManifestPath -PathType Leaf)) {
                throw "Resume requires the original run-manifest.json, which was not found in $($script:RunRoot)."
            }
            try {
                $originalManifest = (Read-Utf8File -Path $originalManifestPath) | ConvertFrom-Json
                $originalProfile = [string]$originalManifest.profile

                $scopeProperty = $originalManifest.PSObject.Properties['scope']
                if (-not $scopeProperty -or -not $scopeProperty.Value) {
                    throw 'the original manifest has no scope object'
                }
                $originalScope = $scopeProperty.Value
                $scopeHashProperty = $originalScope.PSObject.Properties['sha256']
                $scopeCountProperty = $originalScope.PSObject.Properties['count']
                $resolutionHashProperty = $originalScope.PSObject.Properties['resolutionMapSha256']
                $parsedScopeCount = 0
                if (-not $scopeHashProperty -or [string]$scopeHashProperty.Value -notmatch '^[A-Fa-f0-9]{64}$') {
                    throw 'the original manifest has no valid scope SHA-256'
                }
                if (-not $scopeCountProperty -or
                    -not [int]::TryParse([string]$scopeCountProperty.Value, [ref]$parsedScopeCount) -or
                    $parsedScopeCount -lt 1) {
                    throw 'the original manifest has no valid scope target count'
                }
                if (-not $resolutionHashProperty -or [string]$resolutionHashProperty.Value -notmatch '^[A-Fa-f0-9]{64}$') {
                    throw 'the original manifest has no valid resolution-map SHA-256; older runs without this binding cannot be resumed safely'
                }
                $script:OriginalScopeSha256 = ([string]$scopeHashProperty.Value).ToUpperInvariant()
                $script:OriginalScopeCount = $parsedScopeCount
                $script:OriginalResolutionMapSha256 = ([string]$resolutionHashProperty.Value).ToUpperInvariant()

                $toolsProperty = $originalManifest.PSObject.Properties['tools']
                $originalNmap = if ($toolsProperty -and $toolsProperty.Value) {
                    $nmapProperty = $toolsProperty.Value.PSObject.Properties['nmap']
                    if ($nmapProperty) { $nmapProperty.Value } else { $null }
                }
                else { $null }
                if ($originalNmap) {
                    $nmapDataManifestHashProperty = $originalNmap.PSObject.Properties['dataManifestSha256']
                    $nmapDataTreeHashProperty = $originalNmap.PSObject.Properties['dataTreeSha256']
                    $nmapDataDirectoryProperty = $originalNmap.PSObject.Properties['dataDirectory']
                    $nmapExecutableHashProperty = $originalNmap.PSObject.Properties['sha256']
                    if (-not $nmapDataManifestHashProperty -or [string]$nmapDataManifestHashProperty.Value -notmatch '^[A-Fa-f0-9]{64}$' -or
                        -not $nmapDataTreeHashProperty -or [string]$nmapDataTreeHashProperty.Value -notmatch '^[A-Fa-f0-9]{64}$' -or
                        -not $nmapDataDirectoryProperty -or [string]::IsNullOrWhiteSpace([string]$nmapDataDirectoryProperty.Value) -or
                        -not $nmapExecutableHashProperty -or [string]$nmapExecutableHashProperty.Value -notmatch '^[A-Fa-f0-9]{64}$') {
                        throw 'the original manifest has incomplete Nmap executable/data-tree bindings; refusing Resume'
                    }
                    $script:OriginalNmapDataManifestSha256 = ([string]$nmapDataManifestHashProperty.Value).ToUpperInvariant()
                    $script:OriginalNmapDataTreeSha256 = ([string]$nmapDataTreeHashProperty.Value).ToUpperInvariant()
                    $script:OriginalNmapDataDirectory = [IO.Path]::GetFullPath([string]$nmapDataDirectoryProperty.Value)
                    $script:OriginalNmapExecutableSha256 = ([string]$nmapExecutableHashProperty.Value).ToUpperInvariant()
                }
            }
            catch {
                throw "Could not read the original run manifest for Resume: $($_.Exception.Message)"
            }
            if (-not $originalProfile -or $originalProfile -notmatch '^(?i:Quick|Standard|Deep)$') {
                throw 'The original run manifest does not contain a valid scan profile; refusing checkpoint reuse.'
            }
            if ($originalProfile -ine $ScanProfile) {
                throw "Resume profile mismatch: the existing run used $originalProfile, but this invocation requested $ScanProfile. Use -Profile $originalProfile or start a new run."
            }
        }
    }
    else {
        $stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
        $rawHostName = [string]$env:COMPUTERNAME
        if ([string]::IsNullOrWhiteSpace($rawHostName)) { $rawHostName = [Environment]::MachineName }
        $hostName = Get-SafeName -Value $rawHostName
        if (-not $hostName) { $hostName = 'WINDOWS' }
        $suffix = [Guid]::NewGuid().ToString('N').Substring(0, 8)
        $script:RunRoot = Join-Path $outputRoot ('{0}_{1}_{2}' -f $stamp, $hostName, $suffix)
        [void](New-Item -ItemType Directory -Path $script:RunRoot -Force)
    }

    $script:LogDirectory = Join-Path $script:RunRoot 'logs'
    $script:RawDirectory = Join-Path $script:RunRoot 'raw'
    $script:NormalizedDirectory = Join-Path $script:RunRoot 'normalized'
    $script:ReportDirectory = Join-Path $script:RunRoot 'report'
    $script:ScopeDirectory = Join-Path $script:RunRoot 'scope'
    foreach ($directory in @($script:LogDirectory, $script:RawDirectory, $script:NormalizedDirectory, $script:ReportDirectory, $script:ScopeDirectory)) {
        if (-not (Test-Path -LiteralPath $directory)) {
            [void](New-Item -ItemType Directory -Path $directory -Force)
        }
    }
    $script:RunLockStream = Enter-ExclusiveFileLock -Path (Join-Path $script:RunRoot '.cptc-run.lock') -Purpose 'run directory'
    if ($Action -eq 'Install') {
        $script:ToolInstallLockStream = Enter-ExclusiveFileLock -Path (Join-Path $ToolsDirectory '.cptc-install.lock') -Purpose 'tool installation'
    }
    elseif ($Action -eq 'Run' -or $Action -eq 'Doctor') {
        $script:ToolInstallLockStream = Enter-SharedFileLock -Path (Join-Path $ToolsDirectory '.cptc-install.lock') -Purpose 'managed tool set'
    }
    if ($UseExisting -and (($Action -eq 'Report') -or ($Action -eq 'Run' -and $Resume))) {
        $checksumVerification = Test-ExistingArtifactHashes
        $script:ExistingChecksumStatus = $checksumVerification.Status
        $script:ChecksumVerificationIssues = @($checksumVerification.Issues)
        switch ($checksumVerification.Status) {
            'valid' {
                $script:CheckpointIntegrityVerified = $true
                Write-Log -Level INFO -Message ("Verified {0} artifact hash(es) from {1} before modifying the existing run." -f $checksumVerification.Checked, $checksumVerification.Path)
            }
            'missing' {
                # Existing evidence has no trustworthy baseline. Keep final hash
                # generation disabled unless a real Resume run successfully
                # quarantines every derived artifact before rebuilding it.
                $script:SuppressArtifactHashFinalization = $true
                Write-Log -Level WARN -Message ("No existing SHA256SUMS.txt was found in {0}. This may be an interrupted first run; continuing with manifest-bound scope checks where available." -f $script:RunRoot)
            }
            'invalid' {
                $script:EvidenceIntegrityFailure = $true
                foreach ($issue in @($checksumVerification.Issues)) {
                    Write-Log -Level ERROR -Message ("Existing artifact integrity check failed: {0}" -f $issue)
                }
                if ($Action -eq 'Run' -and $Resume) {
                    throw 'Existing artifact checksum verification failed; refusing Resume before any checkpoint reuse.'
                }
            }
        }
    }
    if ($UseExisting) {
        $highestCommandNumber = 0
        foreach ($existingLog in @(Get-ChildItem -LiteralPath $script:LogDirectory -File -ErrorAction SilentlyContinue)) {
            if ($existingLog.Name -match '^(\d+)_.*\.(?:stdout|stderr)\.log$') {
                $number = [int]$Matches[1]
                if ($number -gt $highestCommandNumber) { $highestCommandNumber = $number }
            }
        }
        $script:CommandCounter = $highestCommandNumber
    }
    $logSuffix = '{0}_{1}' -f [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'), ([Guid]::NewGuid().ToString('N').Substring(0, 8))
    $script:RunnerLog = Join-Path $script:LogDirectory ('runner_{0}.log' -f $logSuffix)
    $script:EventLog = Join-Path $script:LogDirectory ('events_{0}.jsonl' -f $logSuffix)
    Write-Utf8File -Path $script:RunnerLog -Content ''
    Write-Utf8File -Path $script:EventLog -Content ''
    $script:TranscriptPath = Join-Path $script:LogDirectory ('transcript_{0}.log' -f $logSuffix)
    try {
        Start-Transcript -Path $script:TranscriptPath -Append | Out-Null
        $script:TranscriptStarted = $true
    }
    catch {
        Write-Log -Level WARN -Message ("PowerShell transcript could not be started: {0}" -f $_.Exception.Message)
    }

    $scriptHash = $null
    if ($script:ScriptPath -and (Test-Path -LiteralPath $script:ScriptPath)) {
        $scriptHash = (Get-FileHash -LiteralPath $script:ScriptPath -Algorithm SHA256).Hash
    }
    if ($UseExisting) {
        $manifestPrefix = if ($Action -eq 'Report') { 'report-manifest' } else { 'resume-manifest' }
        $script:ManifestPath = Join-Path $script:RunRoot ('{0}_{1}.json' -f $manifestPrefix, $logSuffix)
    }
    else {
        $script:ManifestPath = Join-Path $script:RunRoot 'run-manifest.json'
    }
    $script:Manifest = [ordered]@{
        schemaVersion = 1
        action = $Action
        profile = $ScanProfile
        startedUtc = [DateTime]::UtcNow.ToString('o')
        completedUtc = $null
        runDirectory = $script:RunRoot
        scriptPath = $script:ScriptPath
        scriptSha256 = $scriptHash
        computerName = $env:COMPUTERNAME
        userName = [Environment]::UserName
        powerShellVersion = $PSVersionTable.PSVersion.ToString()
        isAdministrator = Get-IsAdministrator
        parameters = [ordered]@{
            maxTargets = $MaxTargets
            maxRate = $MaxRate
            throttle = $Throttle
            hostTimeoutMinutes = $HostTimeoutMinutes
            commandTimeoutSeconds = $CommandTimeoutSeconds
            allowPublicTargets = [bool]$AllowPublicTargets
            udp = [bool]$EnableUdp
            ad = [bool]$EnableAd
            authorizedAdDomain = $AuthorizedAdDomain
            adDomainAcknowledged = [bool]$AcknowledgeAdDomain
            nucleiTemplatesDirectory = $NucleiTemplatesDirectory
            nuclei = [bool]$EnableNuclei
            ffuf = [bool]$EnableFfuf
        }
        scope = $null
        tools = [ordered]@{}
        executedBinaries = [ordered]@{}
        evidenceIntegrity = [ordered]@{
            existingChecksumStatus = $script:ExistingChecksumStatus
            issues = @($script:ChecksumVerificationIssues)
        }
        stages = [ordered]@{}
        exitCode = $null
    }
    Write-RunManifest
    Write-Log -Level INFO -Message ("Run directory: {0}" -f $script:RunRoot)
}

function Write-RunManifest {
    if (-not $script:Manifest -or -not $script:RunRoot) { return }
    if (-not $script:ManifestPath) { $script:ManifestPath = Join-Path $script:RunRoot 'run-manifest.json' }
    Write-Utf8File -Path $script:ManifestPath -Content ($script:Manifest | ConvertTo-Json -Depth 12)
}

function Set-StageStatus {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Status,
        [string]$Detail
    )
    $script:Manifest.stages[$Name] = [ordered]@{
        status = $Status
        timestampUtc = [DateTime]::UtcNow.ToString('o')
        detail = $Detail
    }
    Write-RunManifest
}

function Test-ExistingArtifactHashes {
    $checksumPath = Join-Path $script:RunRoot 'SHA256SUMS.txt'
    if (-not (Test-Path -LiteralPath $checksumPath -PathType Leaf)) {
        return [pscustomobject]@{ Status = 'missing'; Issues = @(); Checked = 0; Path = $checksumPath }
    }
    $issues = New-Object System.Collections.Generic.List[System.String]
    $listedPaths = New-Object -TypeName 'System.Collections.Generic.HashSet[System.String]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
    $checked = 0
    $rootPrefix = [IO.Path]::GetFullPath($script:RunRoot).TrimEnd([char[]]@('\', '/')) + [IO.Path]::DirectorySeparatorChar
    $lineNumber = 0
    $checksumLines = @()
    try {
        $checksumLines = @(Read-Utf8Lines -Path $checksumPath)
    }
    catch {
        [void]$issues.Add(("Could not decode the checksum manifest as UTF-8: {0}" -f $_.Exception.Message))
    }
    foreach ($line in $checksumLines) {
        $lineNumber++
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line -notmatch '^([A-Fa-f0-9]{64})\s{2}(.+)$') {
            [void]$issues.Add(("Malformed checksum line {0}: {1}" -f $lineNumber, $line))
            continue
        }
        $expectedHash = $Matches[1].ToUpperInvariant()
        $relativeKey = (([string]$Matches[2]).Trim() -replace '\\', '/')
        if ($relativeKey -eq '.cptc-run.lock') { continue }
        if (-not $listedPaths.Add($relativeKey)) {
            [void]$issues.Add(("Duplicate checksum entry on line {0}: {1}" -f $lineNumber, $relativeKey))
            continue
        }
        $relativePath = $relativeKey -replace '/', [IO.Path]::DirectorySeparatorChar
        if ([IO.Path]::IsPathRooted($relativePath)) {
            [void]$issues.Add(("Checksum line {0} contains an absolute path: {1}" -f $lineNumber, $relativePath))
            continue
        }
        try {
            $fullPath = [IO.Path]::GetFullPath((Join-Path $script:RunRoot $relativePath))
        }
        catch {
            [void]$issues.Add(("Checksum line {0} has an invalid path {1}: {2}" -f $lineNumber, $relativePath, $_.Exception.Message))
            continue
        }
        if (-not $fullPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            [void]$issues.Add(("Checksum line {0} escapes the run directory: {1}" -f $lineNumber, $relativePath))
            continue
        }
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            [void]$issues.Add(("Listed artifact is missing: {0}" -f $relativePath))
            continue
        }
        try {
            $actualHash = (Get-FileHash -LiteralPath $fullPath -Algorithm SHA256).Hash.ToUpperInvariant()
            $checked++
            if ($actualHash -ne $expectedHash) {
                [void]$issues.Add(("Artifact hash mismatch for {0}: expected {1}, received {2}" -f $relativePath, $expectedHash, $actualHash))
            }
        }
        catch {
            [void]$issues.Add(("Could not hash listed artifact {0}: {1}" -f $relativePath, $_.Exception.Message))
        }
    }
    if ($listedPaths.Count -eq 0) {
        [void]$issues.Add('The checksum manifest contains no artifact entries.')
    }
    try {
        foreach ($currentFile in @(Get-ChildItem -LiteralPath $script:RunRoot -File -Recurse -ErrorAction Stop)) {
            $currentRelative = ($currentFile.FullName.Substring($script:RunRoot.Length).TrimStart('\', '/') -replace '\\', '/')
            if ($currentRelative -eq 'SHA256SUMS.txt' -or $currentRelative -eq '.cptc-run.lock') { continue }
            if (-not $listedPaths.Contains($currentRelative)) {
                [void]$issues.Add(("Unlisted artifact is present: {0}" -f $currentRelative))
            }
        }
    }
    catch {
        [void]$issues.Add(("Could not enumerate current artifacts for checksum verification: {0}" -f $_.Exception.Message))
    }
    return [pscustomobject]@{
        Status = $(if ($issues.Count -eq 0) { 'valid' } else { 'invalid' })
        Issues = $issues.ToArray()
        Checked = $checked
        Path = $checksumPath
    }
}

function Write-ArtifactHashes {
    if (-not $script:RunRoot -or -not (Test-Path -LiteralPath $script:RunRoot)) { return }
    $hashPath = Join-Path $script:RunRoot 'SHA256SUMS.txt'
    $runParent = Split-Path -Parent $script:RunRoot
    $transactionId = [Guid]::NewGuid().ToString('N')
    $stagedChecksumPath = Join-Path $runParent ('.cptc-checksum-{0}.tmp' -f $transactionId)
    $stagedSnapshotPath = Join-Path $runParent ('.cptc-checksum-snapshot-{0}.tmp' -f $transactionId)
    $replacementBackupPath = Join-Path $runParent ('.cptc-checksum-backup-{0}.tmp' -f $transactionId)
    $hadPreviousChecksum = Test-Path -LiteralPath $hashPath -PathType Leaf
    $snapshotPath = $null
    $snapshotMoved = $false
    $lines = New-Object System.Collections.Generic.List[System.String]
    $hashFailures = New-Object System.Collections.Generic.List[System.String]
    try {
        $artifactFiles = @(Get-ChildItem -LiteralPath $script:RunRoot -File -Recurse -ErrorAction Stop | Sort-Object FullName)
        foreach ($file in $artifactFiles) {
            $relative = $file.FullName.Substring($script:RunRoot.Length).TrimStart('\', '/') -replace '\\', '/'
            if ($file.FullName -eq $hashPath -or $relative -eq '.cptc-run.lock') { continue }
            try {
                $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
                [void]$lines.Add(('{0}  {1}' -f $hash, $relative))
            }
            catch {
                [void]$hashFailures.Add(("Could not hash artifact {0}: {1}" -f $relative, $_.Exception.Message))
            }
        }
        if ($hashFailures.Count -gt 0) {
            throw ("Artifact hashing failed for {0} file(s); the previous checksum manifest was preserved. {1}" -f
                $hashFailures.Count, ($hashFailures -join ' | '))
        }
        if ($hadPreviousChecksum) {
            $snapshotName = 'SHA256SUMS.previous_{0}_{1}.txt' -f [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'), $transactionId.Substring(0, 8)
            $snapshotPath = Join-Path $script:RunRoot $snapshotName
            $previousBytes = [IO.File]::ReadAllBytes($hashPath)
            [IO.File]::WriteAllBytes($stagedSnapshotPath, $previousBytes)
            $snapshotHash = (Get-FileHash -LiteralPath $stagedSnapshotPath -Algorithm SHA256).Hash.ToLowerInvariant()
            [void]$lines.Add(('{0}  {1}' -f $snapshotHash, $snapshotName))
        }
        $checksumContent = ((@($lines | Sort-Object) -join [Environment]::NewLine) + [Environment]::NewLine)
        [IO.File]::WriteAllText($stagedChecksumPath, $checksumContent, $script:Utf8NoBom)

        if ($hadPreviousChecksum) {
            [IO.File]::Move($stagedSnapshotPath, $snapshotPath)
            $snapshotMoved = $true
            [IO.File]::Replace($stagedChecksumPath, $hashPath, $replacementBackupPath, $true)
        }
        else {
            [IO.File]::Move($stagedChecksumPath, $hashPath)
        }
    }
    catch {
        if ($snapshotMoved -and $snapshotPath -and (Test-Path -LiteralPath $snapshotPath -PathType Leaf)) {
            try { [IO.File]::Delete($snapshotPath) } catch { }
        }
        throw
    }
    finally {
        foreach ($transactionPath in @($stagedChecksumPath, $stagedSnapshotPath, $replacementBackupPath)) {
            if ($transactionPath -and (Test-Path -LiteralPath $transactionPath -PathType Leaf)) {
                try { [IO.File]::Delete($transactionPath) } catch { }
            }
        }
    }
}

function Convert-IPv4ToUInt32 {
    param([Parameter(Mandatory = $true)][string]$Address)
    # IPAddress.TryParse is the lenient inet_aton parser: it reads a leading-zero
    # octet as OCTAL (010.10.10.5 -> 8.10.10.5), accepts hex (0x0a.0.0.1) and
    # short forms (10.1.1 -> 10.1.0.1).  Require canonical dotted-quad so a
    # transcription artifact cannot silently retarget the scan.
    if ($Address -notmatch '^(?:0|[1-9][0-9]{0,2})(?:\.(?:0|[1-9][0-9]{0,2})){3}$') {
        throw "IPv4 addresses must be canonical dotted-quad with no leading zeros, hex, or short forms: $Address"
    }
    $parsed = $null
    if (-not [Net.IPAddress]::TryParse($Address, [ref]$parsed)) { throw "Invalid IP address: $Address" }
    if ($parsed.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork) {
        throw "Only IPv4 targets are supported by this runner: $Address"
    }
    $bytes = $parsed.GetAddressBytes()
    $value = ([uint64]$bytes[0] * 16777216) + ([uint64]$bytes[1] * 65536) + ([uint64]$bytes[2] * 256) + [uint64]$bytes[3]
    return [uint32]$value
}

function Convert-UInt32ToIPv4 {
    param([Parameter(Mandatory = $true)][uint64]$Value)
    return '{0}.{1}.{2}.{3}' -f (($Value -shr 24) -band 255), (($Value -shr 16) -band 255), (($Value -shr 8) -band 255), ($Value -band 255)
}

function Get-CidrInfo {
    param([Parameter(Mandatory = $true)][string]$Cidr)
    if ($Cidr -notmatch '^([^/]+)/([0-9]{1,2})$') { throw "Invalid IPv4 CIDR: $Cidr" }
    $prefix = [int]$Matches[2]
    if ($prefix -lt 0 -or $prefix -gt 32) { throw "Invalid IPv4 prefix in $Cidr" }
    $addressValue = [uint64](Convert-IPv4ToUInt32 -Address $Matches[1])
    if ($prefix -eq 0) {
        $mask = [uint64]0
        $count = [uint64]4294967296
    }
    else {
        $mask = ([uint64]4294967295 -shl (32 - $prefix)) -band [uint64]4294967295
        $count = [uint64][Math]::Pow(2, (32 - $prefix))
    }
    $start = $addressValue -band $mask
    if ($start -ne $addressValue) {
        # Masking silently would widen an operator's host address into its whole
        # containing network, so refuse and say exactly what to write instead.
        throw ("CIDR has host bits set: {0}; write {1}/{2} to authorize that whole network, or {3}/32 for just that host" -f `
            $Cidr, (Convert-UInt32ToIPv4 -Value $start), $prefix, $Matches[1])
    }
    return [pscustomobject]@{
        Cidr = $Cidr
        Prefix = $prefix
        Start = $start
        End = $start + $count - 1
        Count = $count
    }
}

function Test-IsPrivateIPv4 {
    param([Parameter(Mandatory = $true)][string]$Address)
    $value = [uint64](Convert-IPv4ToUInt32 -Address $Address)
    $ranges = @(
        @([uint64]167772160, [uint64]184549375),       # 10.0.0.0/8
        @([uint64]2886729728, [uint64]2887778303),    # 172.16.0.0/12
        @([uint64]3232235520, [uint64]3232301055),    # 192.168.0.0/16
        @([uint64]2130706432, [uint64]2147483647),    # 127.0.0.0/8
        @([uint64]2851995648, [uint64]2852061183),    # 169.254.0.0/16
        @([uint64]1681915904, [uint64]1686110207)     # 100.64.0.0/10
    )
    foreach ($range in $ranges) {
        if ($value -ge $range[0] -and $value -le $range[1]) { return $true }
    }
    return $false
}

function Test-AddressInCidr {
    param(
        [Parameter(Mandatory = $true)][string]$Address,
        [Parameter(Mandatory = $true)]$CidrInfo
    )
    $value = [uint64](Convert-IPv4ToUInt32 -Address $Address)
    return ($value -ge $CidrInfo.Start -and $value -le $CidrInfo.End)
}

function Assert-ScopeEntryForm {
    param([Parameter(Mandatory = $true)][string]$Entry)
    if ($Entry -match '^[0-9.]+-[0-9.]+$') {
        throw "Nmap-style address ranges are not accepted; use CIDR notation: $Entry"
    }
    $literal = $Entry.Split('/')[0]
    # IPv6 is refused later with its own message.
    if ($literal.Contains(':')) { return }
    # Treat an entry with no letters, or one carrying a hex label, as an address
    # literal and require canonical form; real hostnames are left alone.
    if ($literal -notmatch '[A-Za-z]' -or $literal -match '(^|\.)0[xX][0-9A-Fa-f]+(\.|$)') {
        if ($literal -notmatch '^(?:0|[1-9][0-9]{0,2})(?:\.(?:0|[1-9][0-9]{0,2})){3}$') {
            throw "IPv4 literals must be canonical dotted-quad with no leading zeros, hex, or short forms: $Entry"
        }
    }
}

function Get-ConfigValues {
    param(
        [Parameter(Mandatory = $true)]$Config,
        [Parameter(Mandatory = $true)][string[]]$Names
    )
    $values = New-Object System.Collections.Generic.List[System.String]
    foreach ($name in $Names) {
        if ($Config.PSObject.Properties.Name -contains $name) {
            foreach ($value in @($Config.$name)) {
                if ($null -ne $value -and ([string]$value).Trim()) { [void]$values.Add(([string]$value).Trim()) }
            }
        }
    }
    if ($Config.PSObject.Properties.Name -contains 'scope' -and $Config.scope) {
        foreach ($name in $Names) {
            if ($Config.scope.PSObject.Properties.Name -contains $name) {
                foreach ($value in @($Config.scope.$name)) {
                    if ($null -ne $value -and ([string]$value).Trim()) { [void]$values.Add(([string]$value).Trim()) }
                }
            }
        }
    }
    return $values.ToArray()
}

function Split-TargetEntries {
    param([string[]]$Values)
    $result = New-Object System.Collections.Generic.List[System.String]
    foreach ($value in @($Values)) {
        foreach ($part in ([string]$value -split '[,;]')) {
            $clean = ($part -replace '#.*$', '').Trim()
            if ($clean) { [void]$result.Add($clean) }
        }
    }
    return $result.ToArray()
}

function Resolve-Scope {
    $resumeScopeSnapshot = $null
    if ($Resume) {
        try { $resumeScopeSnapshot = Assert-OriginalResumeScopeIntegrity }
        catch {
            $script:EvidenceIntegrityFailure = $true
            throw
        }
    }
    $targetEntries = New-Object System.Collections.Generic.List[System.String]
    $excludeEntries = New-Object System.Collections.Generic.List[System.String]
    foreach ($entry in @(Split-TargetEntries -Values $Target)) { [void]$targetEntries.Add($entry) }
    foreach ($entry in @(Split-TargetEntries -Values $Exclude)) { [void]$excludeEntries.Add($entry) }

    if ($TargetsFile) {
        $targetFilePath = Get-FullPath -Path $TargetsFile
        if (-not (Test-Path -LiteralPath $targetFilePath -PathType Leaf)) { throw "Targets file not found: $targetFilePath" }
        foreach ($entry in @(Split-TargetEntries -Values @(Read-Utf8Lines -Path $targetFilePath))) {
            [void]$targetEntries.Add($entry)
        }
    }

    if ($ConfigPath) {
        $configFullPath = Get-FullPath -Path $ConfigPath
        if (-not (Test-Path -LiteralPath $configFullPath -PathType Leaf)) { throw "Config file not found: $configFullPath" }
        $config = (Read-Utf8File -Path $configFullPath) | ConvertFrom-Json
        foreach ($entry in @(Get-ConfigValues -Config $config -Names @('ranges', 'hosts', 'targets'))) {
            [void]$targetEntries.Add($entry)
        }
        foreach ($entry in @(Get-ConfigValues -Config $config -Names @('exclude', 'excludes', 'excludedTargets'))) {
            [void]$excludeEntries.Add($entry)
        }
    }

    $suppliedScopeInput = ($targetEntries.Count -gt 0)
    $existingTargetPath = Join-Path $script:ScopeDirectory 'targets.txt'
    if ($targetEntries.Count -eq 0 -and $Resume -and $resumeScopeSnapshot) {
        foreach ($entry in @($resumeScopeSnapshot.Targets)) {
            [void]$targetEntries.Add($entry)
        }
        Write-Log -Level INFO -Message ("Resume: reusing normalized scope from {0}." -f $existingTargetPath)
    }

    if ($targetEntries.Count -eq 0) {
        throw 'No targets supplied. Use -Target, -TargetsFile, or -ConfigPath with ranges/hosts.'
    }

    $targets = New-Object -TypeName 'System.Collections.Generic.HashSet[System.String]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
    $sourceMap = New-Object System.Collections.Generic.List[System.Object]
    foreach ($entry in $targetEntries) {
        if ($entry -match '^[a-zA-Z][a-zA-Z0-9+.-]*://') {
            throw "URLs are not accepted as scope entries; provide an IP, CIDR, or hostname: $entry"
        }
        Assert-ScopeEntryForm -Entry $entry
        if ($entry.Contains('/')) {
            $cidr = Get-CidrInfo -Cidr $entry
            if ($cidr.Count -gt [uint64]$MaxTargets) {
                throw "CIDR $entry expands to $($cidr.Count) addresses, above -MaxTargets $MaxTargets."
            }
            for ($current = [uint64]$cidr.Start; $current -le [uint64]$cidr.End; $current++) {
                $address = Convert-UInt32ToIPv4 -Value $current
                [void]$targets.Add($address)
                if ($targets.Count -gt $MaxTargets) { throw "Resolved scope exceeds -MaxTargets $MaxTargets." }
            }
            [void]$sourceMap.Add([pscustomobject]@{ input = $entry; resolved = $entry; kind = 'cidr' })
            continue
        }

        $parsed = $null
        if ([Net.IPAddress]::TryParse($entry, [ref]$parsed)) {
            if ($parsed.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork) {
                throw "IPv6 is not supported by this runner: $entry"
            }
            $address = $parsed.ToString()
            [void]$targets.Add($address)
            [void]$sourceMap.Add([pscustomobject]@{ input = $entry; resolved = $address; kind = 'address' })
        }
        else {
            if ($entry -notmatch '^[A-Za-z0-9][A-Za-z0-9.-]{0,252}$' -or $entry.Contains('..')) {
                throw "Invalid hostname: $entry"
            }
            try {
                $addresses = @([Net.Dns]::GetHostAddresses($entry) |
                    Where-Object { $_.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork } |
                    ForEach-Object { $_.ToString() } | Sort-Object -Unique)
            }
            catch {
                throw "Could not resolve hostname $entry`: $($_.Exception.Message)"
            }
            if ($addresses.Count -eq 0) { throw "Hostname $entry did not resolve to an IPv4 address." }
            foreach ($address in $addresses) {
                [void]$targets.Add($address)
                [void]$sourceMap.Add([pscustomobject]@{ input = $entry; resolved = $address; kind = 'hostname' })
                if ($targets.Count -gt $MaxTargets) { throw "Resolved scope exceeds -MaxTargets $MaxTargets." }
            }
        }
    }

    $excludeIps = New-Object -TypeName 'System.Collections.Generic.HashSet[System.String]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
    $excludeCidrs = New-Object System.Collections.Generic.List[System.Object]
    foreach ($entry in $excludeEntries) {
        Assert-ScopeEntryForm -Entry $entry
        if ($entry.Contains('/')) {
            [void]$excludeCidrs.Add((Get-CidrInfo -Cidr $entry))
            continue
        }
        $parsed = $null
        if ([Net.IPAddress]::TryParse($entry, [ref]$parsed)) {
            if ($parsed.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork) { throw "IPv6 exclusion is not supported: $entry" }
            [void]$excludeIps.Add($parsed.ToString())
            continue
        }
        try {
            $excludeAddresses = @([Net.Dns]::GetHostAddresses($entry) |
                Where-Object { $_.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork } |
                ForEach-Object { $_.ToString() } | Sort-Object -Unique)
        }
        catch {
            throw "Could not resolve excluded hostname $entry`: $($_.Exception.Message)"
        }
        # Fail closed: an AAAA-only name would otherwise leave the exclusion
        # empty and the de-authorized host would be scanned with no warning.
        if ($excludeAddresses.Count -eq 0) {
            throw "Excluded hostname $entry returned no IPv4 address; this runner cannot exclude it, so refusing the scope."
        }
        foreach ($address in $excludeAddresses) { [void]$excludeIps.Add($address) }
    }

    $finalTargets = New-Object System.Collections.Generic.List[System.String]
    foreach ($address in $targets) {
        $isExcluded = $excludeIps.Contains($address)
        if (-not $isExcluded) {
            foreach ($cidr in $excludeCidrs) {
                if (Test-AddressInCidr -Address $address -CidrInfo $cidr) {
                    $isExcluded = $true
                    break
                }
            }
        }
        if (-not $isExcluded) { [void]$finalTargets.Add($address) }
    }
    $sortedTargets = @($finalTargets | Sort-Object { [uint64](Convert-IPv4ToUInt32 -Address $_) } -Unique)
    if ($sortedTargets.Count -eq 0) { throw 'All supplied targets were excluded.' }
    if ($sortedTargets.Count -gt $MaxTargets) { throw "Resolved scope exceeds -MaxTargets $MaxTargets." }

    if (-not $AllowPublicTargets) {
        $public = @($sortedTargets | Where-Object { -not (Test-IsPrivateIPv4 -Address $_) })
        if ($public.Count -gt 0) {
            $sample = ($public | Select-Object -First 5) -join ', '
            throw "Scope contains $($public.Count) non-private address(es), including $sample. Confirm they are authorized and pass -AllowPublicTargets."
        }
    }

    $targetPath = Join-Path $script:ScopeDirectory 'targets.txt'
    $targetContent = ($sortedTargets -join [Environment]::NewLine) + [Environment]::NewLine
    $desiredScopeHash = Get-TextSha256 -Content $targetContent
    if ($Resume) {
        if ($desiredScopeHash -ine $script:OriginalScopeSha256 -or $sortedTargets.Count -ne $script:OriginalScopeCount) {
            $script:EvidenceIntegrityFailure = $true
            throw ("Resume scope differs from the original run manifest (original {0} target(s), SHA-256 {1}; requested {2} target(s), SHA-256 {3}). Start a new run or supply the exact original scope." -f
                $script:OriginalScopeCount, $script:OriginalScopeSha256, $sortedTargets.Count, $desiredScopeHash)
        }
        $script:ResumeScopeMatches = $true
    }
    Write-Utf8File -Path $targetPath -Content $targetContent
    $mapPath = Join-Path $script:ScopeDirectory 'resolution-map.json'
    if ($Resume -and (Test-Path -LiteralPath $mapPath -PathType Leaf)) {
        Write-Log -Level INFO -Message ("Resume: preserving the original hostname resolution provenance in {0}." -f $mapPath)
        if ($suppliedScopeInput) {
            $resumeMapName = 'resolution-map-resume_{0}_{1}.json' -f [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'), ([Guid]::NewGuid().ToString('N').Substring(0, 8))
            $resumeMapPath = Join-Path $script:ScopeDirectory $resumeMapName
            Write-Utf8File -Path $resumeMapPath -Content ($sourceMap.ToArray() | ConvertTo-Json -Depth 5)
            Write-Log -Level INFO -Message ("Resume: wrote this invocation's matching resolution evidence to {0}." -f $resumeMapPath)
        }
    }
    else {
        Write-Utf8File -Path $mapPath -Content ($sourceMap.ToArray() | ConvertTo-Json -Depth 5)
    }
    $resolutionMapHash = (Get-FileHash -LiteralPath $mapPath -Algorithm SHA256).Hash
    if ($Resume -and $resolutionMapHash -ine $script:OriginalResolutionMapSha256) {
        $script:EvidenceIntegrityFailure = $true
        throw "Resume resolution-map integrity changed during scope preparation; refusing checkpoint reuse."
    }
    $scopeHash = $desiredScopeHash
    $scope = [pscustomobject]@{
        Targets = $sortedTargets
        TargetFile = $targetPath
        ResolutionMap = $mapPath
        Count = $sortedTargets.Count
        Sha256 = $scopeHash
    }
    $script:Manifest.scope = [ordered]@{
        count = $scope.Count
        sha256 = $scope.Sha256
        targetFile = $scope.TargetFile
        resolutionMap = $scope.ResolutionMap
        resolutionMapSha256 = $resolutionMapHash
        publicTargetsAllowed = [bool]$AllowPublicTargets
    }
    Write-RunManifest
    Write-Log -Level INFO -Message ("Validated {0} target(s); scope SHA-256 {1}." -f $scope.Count, $scope.Sha256)
    return $scope
}

function Confirm-Scope {
    param([Parameter(Mandatory = $true)]$Scope)
    if ($WhatIfPreference) {
        Write-Log -Level INFO -Message 'WhatIf is active; network commands will be displayed but not run.'
        return
    }
    if ($AcknowledgeScope) { return }
    if ($NonInteractive) {
        throw '-AcknowledgeScope is required for a non-interactive network run.'
    }
    Write-Host ''
    Write-Host ("Network enumeration is limited to {0} normalized target(s)." -f $Scope.Count) -ForegroundColor Yellow
    Write-Host ("Scope file: {0}" -f $Scope.TargetFile)
    Write-Host ("Scope SHA-256: {0}" -f $Scope.Sha256)
    $answer = Read-Host 'Type YES to confirm these targets are authorized'
    if ($answer -cne 'YES') { throw 'Scope was not acknowledged.' }
}

function Invoke-Collector {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$ScriptBlock,
        [string]$Directory = $script:RawDirectory
    )
    $path = Join-Path $Directory ((Get-SafeName -Value $Name) + '.json')
    try {
        Write-Log -Level INFO -Message ("Collecting {0}." -f $Name)
        $result = @(& $ScriptBlock)
        $json = if ($result.Count -eq 0) { '[]' } else { $result | ConvertTo-Json -Depth 8 }
        Write-Utf8File -Path $path -Content $json
        Write-Log -Level SUCCESS -Message ("Collected {0} -> {1}" -f $Name, $path)
        return $result
    }
    catch {
        $script:CollectorFailureCount++
        Write-Log -Level WARN -Message ("Collector {0} was unavailable or failed: {1}" -f $Name, $_.Exception.Message)
        Write-Utf8File -Path $path -Content (([ordered]@{ error = $_.Exception.Message; timestampUtc = [DateTime]::UtcNow.ToString('o') }) | ConvertTo-Json)
        return @()
    }
}

function Invoke-LocalInventory {
    $stageErrorStart = $script:ErrorCount
    $collectorFailureStart = $script:CollectorFailureCount
    Set-StageStatus -Name 'localInventory' -Status 'running'
    $localDirectory = Join-Path $script:RawDirectory 'local'
    if (-not (Test-Path -LiteralPath $localDirectory)) { [void](New-Item -ItemType Directory -Path $localDirectory -Force) }

    Invoke-Collector -Name 'computer-info' -Directory $localDirectory -ScriptBlock {
        if (Get-Command Get-ComputerInfo -ErrorAction SilentlyContinue) { Get-ComputerInfo }
        else { Get-CimInstance Win32_OperatingSystem; Get-CimInstance Win32_ComputerSystem }
    } | Out-Null
    Invoke-Collector -Name 'network-configuration' -Directory $localDirectory -ScriptBlock {
        Get-NetIPConfiguration -Detailed -ErrorAction Stop
    } | Out-Null
    Invoke-Collector -Name 'routes' -Directory $localDirectory -ScriptBlock { Get-NetRoute | Sort-Object DestinationPrefix, RouteMetric } | Out-Null
    Invoke-Collector -Name 'neighbors' -Directory $localDirectory -ScriptBlock { Get-NetNeighbor | Sort-Object InterfaceIndex, IPAddress } | Out-Null
    Invoke-Collector -Name 'dns-servers' -Directory $localDirectory -ScriptBlock { Get-DnsClientServerAddress } | Out-Null
    Invoke-Collector -Name 'dns-cache' -Directory $localDirectory -ScriptBlock { Get-DnsClientCache } | Out-Null
    Invoke-Collector -Name 'tcp-connections' -Directory $localDirectory -ScriptBlock { Get-NetTCPConnection | Sort-Object State, LocalPort } | Out-Null
    Invoke-Collector -Name 'udp-endpoints' -Directory $localDirectory -ScriptBlock { Get-NetUDPEndpoint | Sort-Object LocalPort } | Out-Null
    Invoke-Collector -Name 'processes' -Directory $localDirectory -ScriptBlock { Get-Process | Select-Object Name, Id, Path, StartTime, Company, ProductVersion } | Out-Null
    Invoke-Collector -Name 'services' -Directory $localDirectory -ScriptBlock { Get-CimInstance Win32_Service | Select-Object Name, DisplayName, State, StartMode, StartName, PathName } | Out-Null
    Invoke-Collector -Name 'hotfixes' -Directory $localDirectory -ScriptBlock { Get-CimInstance Win32_QuickFixEngineering } | Out-Null
    Invoke-Collector -Name 'installed-software' -Directory $localDirectory -ScriptBlock {
        $paths = @(
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )
        Get-ItemProperty -Path $paths -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName } |
            Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, InstallLocation |
            Sort-Object DisplayName, DisplayVersion -Unique
    } | Out-Null
    Invoke-Collector -Name 'firewall-profiles' -Directory $localDirectory -ScriptBlock { Get-NetFirewallProfile } | Out-Null
    Invoke-Collector -Name 'scheduled-tasks' -Directory $localDirectory -ScriptBlock { Get-ScheduledTask | Select-Object TaskPath, TaskName, State, Author, Description } | Out-Null
    Invoke-Collector -Name 'smb-shares' -Directory $localDirectory -ScriptBlock { Get-SmbShare } | Out-Null
    Invoke-Collector -Name 'smb-server-configuration' -Directory $localDirectory -ScriptBlock { Get-SmbServerConfiguration } | Out-Null
    Invoke-Collector -Name 'defender-status' -Directory $localDirectory -ScriptBlock { Get-MpComputerStatus } | Out-Null
    Invoke-Collector -Name 'bitlocker' -Directory $localDirectory -ScriptBlock { Get-BitLockerVolume } | Out-Null
    Invoke-Collector -Name 'local-administrators' -Directory $localDirectory -ScriptBlock {
        if (Get-Command Get-LocalGroupMember -ErrorAction SilentlyContinue) { Get-LocalGroupMember -Group 'Administrators' }
        else { Get-CimInstance Win32_GroupUser | Where-Object { $_.GroupComponent -match 'Name="Administrators"' } }
    } | Out-Null

    foreach ($native in @(
        @{ Name = 'whoami-all'; File = (Join-Path $env:SystemRoot 'System32\whoami.exe'); Args = @('/all') },
        @{ Name = 'ipconfig-all'; File = (Join-Path $env:SystemRoot 'System32\ipconfig.exe'); Args = @('/all') },
        @{ Name = 'route-print'; File = (Join-Path $env:SystemRoot 'System32\route.exe'); Args = @('print') },
        @{ Name = 'arp-all'; File = (Join-Path $env:SystemRoot 'System32\arp.exe'); Args = @('-a') },
        @{ Name = 'netstat'; File = (Join-Path $env:SystemRoot 'System32\netstat.exe'); Args = @('-ano') },
        @{ Name = 'audit-policy'; File = (Join-Path $env:SystemRoot 'System32\auditpol.exe'); Args = @('/get', '/category:*') },
        @{ Name = 'kerberos-tickets'; File = (Join-Path $env:SystemRoot 'System32\klist.exe'); Args = @() },
        @{ Name = 'sessions'; File = (Join-Path $env:SystemRoot 'System32\query.exe'); Args = @('session') }
    )) {
        if (Test-Path -LiteralPath $native.File) {
            Invoke-LoggedProcess -FilePath $native.File -ArgumentList $native.Args -Name $native.Name -TimeoutSeconds 120 -ContinueOnError | Out-Null
        }
    }
    $status = if ($script:ErrorCount -gt $stageErrorStart -or $script:CollectorFailureCount -gt $collectorFailureStart) { 'partial' } else { 'complete' }
    Set-StageStatus -Name 'localInventory' -Status $status
}

function Test-NpcapAvailable {
    $getServiceCommand = Get-Command -Name 'Get-Service' -CommandType Cmdlet -ErrorAction SilentlyContinue
    if (-not $getServiceCommand) {
        return $false
    }

    try {
        $service = Get-Service -Name 'npcap', 'npf' -ErrorAction SilentlyContinue | Select-Object -First 1
        return [bool]$service
    }
    catch {
        return $false
    }
}

function Get-SelectedNmapScripts {
    $selectedScripts = @(
        'banner', 'ssh-hostkey', 'ssh-auth-methods', 'ftp-anon', 'ftp-syst',
        'smtp-commands', 'smtp-ntlm-info', 'http-title', 'http-headers',
        'http-methods', 'http-auth-finder', 'ssl-cert', 'ssl-enum-ciphers',
        'smb-protocols', 'smb2-security-mode', 'smb2-time', 'smb-os-discovery',
        'smb-enum-shares', 'rdp-enum-encryption', 'rdp-ntlm-info',
        'ldap-rootdse', 'rpcinfo', 'nfs-showmount', 'ms-sql-info',
        'mysql-info', 'mongodb-info', 'redis-info'
    )
    if ($ScanProfile -eq 'Deep') {
        $selectedScripts += @('http-enum', 'smb-enum-users')
    }
    return @($selectedScripts | Sort-Object -Unique)
}

function Assert-NmapRegularNonReparseItem {
    param(
        [Parameter(Mandatory = $true)]$Item,
        [Parameter(Mandatory = $true)][ValidateSet('File', 'Directory')][string]$ExpectedType
    )
    $linkTypeProperty = $Item.PSObject.Properties['LinkType']
    $isLink = $linkTypeProperty -and -not [string]::IsNullOrWhiteSpace([string]$linkTypeProperty.Value)
    $isReparsePoint = (($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)
    if ($isLink -or $isReparsePoint) {
        throw "Nmap data integrity rejected a symlink/reparse point: $($Item.FullName)"
    }
    if ($ExpectedType -eq 'Directory' -and -not $Item.PSIsContainer) {
        throw "Required Nmap data directory is not a directory: $($Item.FullName)"
    }
    if ($ExpectedType -eq 'File' -and $Item.PSIsContainer) {
        throw "Required Nmap data file is not a regular file: $($Item.FullName)"
    }
    if ($ExpectedType -eq 'File') {
        $unixModeProperty = $Item.PSObject.Properties['UnixMode']
        $unixMode = if ($unixModeProperty) { [string]$unixModeProperty.Value } else { '' }
        if (($Item.Attributes -band [IO.FileAttributes]::Device) -ne 0 -or
            ($unixMode -and -not $unixMode.StartsWith('-', [StringComparison]::Ordinal))) {
            throw "Required Nmap data file is not a regular file: $($Item.FullName)"
        }
    }
}

function Assert-NmapPathAncestorsNonReparse {
    param([Parameter(Mandatory = $true)][string]$Path)
    $currentItem = Get-Item -LiteralPath ([IO.Path]::GetFullPath($Path)) -Force -ErrorAction Stop
    if (-not $currentItem.PSIsContainer) {
        $currentItem = Get-Item -LiteralPath $currentItem.Directory.FullName -Force -ErrorAction Stop
    }
    while ($currentItem) {
        Assert-NmapRegularNonReparseItem -Item $currentItem -ExpectedType Directory
        $parent = $currentItem.Parent
        if (-not $parent -or $parent.FullName -eq $currentItem.FullName) { break }
        $currentItem = Get-Item -LiteralPath $parent.FullName -Force -ErrorAction Stop
    }
}

function Assert-NmapDataDirectoryLayout {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string[]]$SelectedScripts = @()
    )
    $rootItem = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    Assert-NmapRegularNonReparseItem -Item $rootItem -ExpectedType Directory
    Assert-NmapPathAncestorsNonReparse -Path $rootItem.FullName

    foreach ($relativeFile in @(
        'nmap-services', 'nmap-service-probes', 'nmap-mac-prefixes',
        'nmap-os-db', 'nmap-payloads', 'nmap-protocols', 'nmap-rpc',
        'nse_main.lua'
    )) {
        $requiredFile = Get-Item -LiteralPath (Join-Path $rootItem.FullName $relativeFile) -Force -ErrorAction Stop
        Assert-NmapRegularNonReparseItem -Item $requiredFile -ExpectedType File
    }
    $scriptsDirectory = Get-Item -LiteralPath (Join-Path $rootItem.FullName 'scripts') -Force -ErrorAction Stop
    Assert-NmapRegularNonReparseItem -Item $scriptsDirectory -ExpectedType Directory
    $scriptDatabase = Get-Item -LiteralPath (Join-Path $scriptsDirectory.FullName 'script.db') -Force -ErrorAction Stop
    Assert-NmapRegularNonReparseItem -Item $scriptDatabase -ExpectedType File
    $nselibDirectory = Get-Item -LiteralPath (Join-Path $rootItem.FullName 'nselib') -Force -ErrorAction Stop
    Assert-NmapRegularNonReparseItem -Item $nselibDirectory -ExpectedType Directory

    foreach ($scriptName in @($SelectedScripts | Sort-Object -Unique)) {
        if ($scriptName -notmatch '^[A-Za-z0-9][A-Za-z0-9_-]*$') {
            throw "Refusing unsafe Nmap NSE name: $scriptName"
        }
        $scriptFile = Get-Item -LiteralPath (Join-Path $scriptsDirectory.FullName ($scriptName + '.nse')) -Force -ErrorAction Stop
        Assert-NmapRegularNonReparseItem -Item $scriptFile -ExpectedType File
    }
}

function Get-NmapDataDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$NmapPath,
        [string[]]$SelectedScripts = @()
    )
    $nmapItem = Get-Item -LiteralPath ([IO.Path]::GetFullPath($NmapPath)) -Force -ErrorAction Stop
    Assert-NmapRegularNonReparseItem -Item $nmapItem -ExpectedType File
    Assert-NmapPathAncestorsNonReparse -Path $nmapItem.FullName
    $executableDirectory = [IO.Path]::GetFullPath($nmapItem.Directory.FullName)
    try {
        Assert-NmapDataDirectoryLayout -Path $executableDirectory -SelectedScripts $SelectedScripts
        return $executableDirectory
    }
    catch {
        throw ("The directory containing nmap.exe is not a complete, safe official Windows Nmap data directory ({0}): {1}. Refusing adjacent or per-user fallback data." -f
            $executableDirectory, $_.Exception.Message)
    }
}

function Get-NmapAmbientUserDataPaths {
    $basePaths = New-Object System.Collections.Generic.List[System.String]
    foreach ($specialFolder in @(
        [Environment+SpecialFolder]::ApplicationData,
        [Environment+SpecialFolder]::LocalApplicationData
    )) {
        try {
            $specialPath = [Environment]::GetFolderPath($specialFolder)
            if (-not [string]::IsNullOrWhiteSpace($specialPath)) { [void]$basePaths.Add($specialPath) }
        }
        catch { }
    }
    foreach ($environmentPath in @($env:APPDATA, $env:LOCALAPPDATA)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$environmentPath)) { [void]$basePaths.Add([string]$environmentPath) }
    }

    $candidatePaths = New-Object System.Collections.Generic.List[System.String]
    foreach ($basePath in $basePaths) {
        [void]$candidatePaths.Add((Join-Path ([IO.Path]::GetFullPath($basePath)) 'nmap'))
    }
    foreach ($profilePath in @($env:USERPROFILE, $env:HOME)) {
        if ([string]::IsNullOrWhiteSpace([string]$profilePath)) { continue }
        $fullProfilePath = [IO.Path]::GetFullPath([string]$profilePath)
        [void]$candidatePaths.Add((Join-Path $fullProfilePath '.nmap'))
        [void]$candidatePaths.Add((Join-Path $fullProfilePath 'nmap'))
    }
    return @($candidatePaths.ToArray() | Select-Object -Unique)
}

function Assert-NmapAmbientUserDataClean {
    foreach ($candidatePath in @(Get-NmapAmbientUserDataPaths)) {
        if (-not (Test-Path -LiteralPath $candidatePath)) { continue }
        $candidateItem = Get-Item -LiteralPath $candidatePath -Force -ErrorAction Stop
        Assert-NmapRegularNonReparseItem -Item $candidateItem -ExpectedType Directory
        $ambientEntries = @([IO.Directory]::GetFileSystemEntries($candidateItem.FullName))
        if ($ambientEntries.Count -gt 0) {
            throw "Ambient Nmap user-data directory is nonempty and could shadow frozen scan inputs: $($candidateItem.FullName)"
        }
    }
}

function Get-NmapProcessIsolation {
    if ($script:NmapProcessIsolation) { return $script:NmapProcessIsolation }
    if ([string]::IsNullOrWhiteSpace($script:ScopeDirectory)) {
        throw 'The run scope directory is unavailable for Nmap process isolation.'
    }
    $root = Join-Path $script:ScopeDirectory 'nmap-process-environment'
    $appData = Join-Path $root 'appdata'
    $localAppData = Join-Path $root 'localappdata'
    $profileDirectory = Join-Path $root 'profile'
    $homeDirectory = Join-Path $root 'home'
    $workingDirectory = Join-Path $root 'cwd'
    foreach ($directory in @($root, $appData, $localAppData, $profileDirectory, $homeDirectory, $workingDirectory)) {
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
            [void](New-Item -ItemType Directory -Path $directory -Force)
        }
    }
    $script:NmapProcessIsolation = [pscustomobject]@{
        Root = [IO.Path]::GetFullPath($root)
        AppData = [IO.Path]::GetFullPath($appData)
        LocalAppData = [IO.Path]::GetFullPath($localAppData)
        Profile = [IO.Path]::GetFullPath($profileDirectory)
        Home = [IO.Path]::GetFullPath($homeDirectory)
        WorkingDirectory = [IO.Path]::GetFullPath($workingDirectory)
    }
    return $script:NmapProcessIsolation
}

function Assert-NmapProcessEnvironmentIsolated {
    Assert-NmapAmbientUserDataClean
    $isolation = Get-NmapProcessIsolation
    $rootItem = Get-Item -LiteralPath $isolation.Root -Force -ErrorAction Stop
    Assert-NmapRegularNonReparseItem -Item $rootItem -ExpectedType Directory
    Assert-NmapPathAncestorsNonReparse -Path $rootItem.FullName
    foreach ($directory in @($isolation.AppData, $isolation.LocalAppData, $isolation.Profile, $isolation.Home, $isolation.WorkingDirectory)) {
        $directoryItem = Get-Item -LiteralPath $directory -Force -ErrorAction Stop
        Assert-NmapRegularNonReparseItem -Item $directoryItem -ExpectedType Directory
        if (@([IO.Directory]::GetFileSystemEntries($directoryItem.FullName)).Count -gt 0) {
            throw "The run-owned Nmap process isolation directory is not empty: $($directoryItem.FullName)"
        }
    }
}

function Test-NmapProcessEnvironmentIntegrity {
    param(
        [Parameter(Mandatory = $true)][string]$Moment,
        [switch]$MarkDataIntegrityFailure
    )
    try {
        Assert-NmapProcessEnvironmentIsolated
        return $true
    }
    catch {
        if ($MarkDataIntegrityFailure) { $script:NmapDataIntegrityFailed = $true }
        Write-Log -Level ERROR -Message ("Nmap process-environment integrity failed {0}: {1}. Ambient per-user data will not be used." -f $Moment, $_.Exception.Message)
        return $false
    }
}

function Get-NmapDataTreeEntries {
    param([Parameter(Mandatory = $true)][string]$Path)
    $root = [IO.Path]::GetFullPath($Path).TrimEnd([char[]]@('\', '/'))
    $rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
    $pending = New-Object -TypeName 'System.Collections.Generic.Queue[System.String]'
    $pending.Enqueue($root)
    while ($pending.Count -gt 0) {
        $currentPath = $pending.Dequeue()
        $currentItem = Get-Item -LiteralPath $currentPath -Force -ErrorAction Stop
        $expectedType = if ($currentItem.PSIsContainer) { 'Directory' } else { 'File' }
        Assert-NmapRegularNonReparseItem -Item $currentItem -ExpectedType $expectedType
        $fullCurrentPath = [IO.Path]::GetFullPath($currentItem.FullName)
        $relativePath = if ($fullCurrentPath -ieq $root) {
            '.'
        }
        elseif ($fullCurrentPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            $fullCurrentPath.Substring($rootPrefix.Length).Replace('\', '/')
        }
        else {
            throw "Nmap data-tree enumeration escaped its root: $fullCurrentPath"
        }
        [pscustomobject]@{
            Type = $expectedType
            RelativePath = $relativePath
            FullPath = $fullCurrentPath
        }
        if ($currentItem.PSIsContainer) {
            foreach ($childPath in @([IO.Directory]::GetFileSystemEntries($fullCurrentPath) | Sort-Object)) {
                $pending.Enqueue([IO.Path]::GetFullPath($childPath))
            }
        }
    }
}

function Get-NmapRegularFileHashRecord {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )
    $before = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    Assert-NmapRegularNonReparseItem -Item $before -ExpectedType File
    $beforeWriteTicks = $before.LastWriteTimeUtc.Ticks
    $sha256 = [Security.Cryptography.SHA256]::Create()
    $stream = $null
    try {
        $stream = [IO.File]::Open($before.FullName, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
        $length = [int64]$stream.Length
        $hash = ([BitConverter]::ToString($sha256.ComputeHash($stream))).Replace('-', '').ToUpperInvariant()
    }
    finally {
        if ($stream) { $stream.Dispose() }
        $sha256.Dispose()
    }
    $after = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    Assert-NmapRegularNonReparseItem -Item $after -ExpectedType File
    if ([int64]$after.Length -ne $length -or $after.LastWriteTimeUtc.Ticks -ne $beforeWriteTicks) {
        throw "Nmap data file changed while it was being hashed: $Path"
    }
    return [pscustomobject]@{
        Type = 'File'
        RelativePath = $RelativePath
        Length = $length
        Sha256 = $hash
    }
}

function Get-NmapDataTreeSnapshot {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string[]]$SelectedScripts = @()
    )
    $fullPath = [IO.Path]::GetFullPath($Path)
    Assert-NmapDataDirectoryLayout -Path $fullPath -SelectedScripts $SelectedScripts
    $initialEntries = @(Get-NmapDataTreeEntries -Path $fullPath)
    $records = New-Object System.Collections.Generic.List[System.Object]
    foreach ($entry in $initialEntries) {
        if ($entry.Type -eq 'Directory') {
            [void]$records.Add([pscustomobject]@{
                Type = 'Directory'
                RelativePath = [string]$entry.RelativePath
                Length = $null
                Sha256 = $null
            })
        }
        else {
            [void]$records.Add((Get-NmapRegularFileHashRecord -Path $entry.FullPath -RelativePath $entry.RelativePath))
        }
    }

    $finalEntries = @(Get-NmapDataTreeEntries -Path $fullPath)
    $initialIdentity = @($initialEntries | ForEach-Object { '{0}`t{1}' -f $_.Type, $_.RelativePath } | Sort-Object)
    $finalIdentity = @($finalEntries | ForEach-Object { '{0}`t{1}' -f $_.Type, $_.RelativePath } | Sort-Object)
    if (($initialIdentity -join "`n") -cne ($finalIdentity -join "`n")) {
        throw "The Nmap data tree changed while it was being inventoried: $fullPath"
    }

    $sortedRecords = @($records.ToArray() | Sort-Object RelativePath, Type)
    $canonicalLines = New-Object System.Collections.Generic.List[System.String]
    foreach ($record in $sortedRecords) {
        if ($record.Type -eq 'Directory') {
            [void]$canonicalLines.Add(('D`t{0}' -f $record.RelativePath))
        }
        else {
            [void]$canonicalLines.Add(('F`t{0}`t{1}`t{2}' -f $record.RelativePath, $record.Length, $record.Sha256))
        }
    }
    $canonicalText = ($canonicalLines.ToArray() -join "`n") + "`n"
    return [pscustomobject]@{
        Path = $fullPath
        TreeSha256 = (Get-TextSha256 -Content $canonicalText).ToUpperInvariant()
        FileCount = @($sortedRecords | Where-Object { $_.Type -eq 'File' }).Count
        DirectoryCount = @($sortedRecords | Where-Object { $_.Type -eq 'Directory' }).Count
        Records = $sortedRecords
    }
}

function Initialize-NmapDataBaseline {
    param(
        [Parameter(Mandatory = $true)][string]$NmapPath,
        [Parameter(Mandatory = $true)][string[]]$SelectedScripts
    )
    $fullNmapPath = [IO.Path]::GetFullPath($NmapPath)
    $nmapSha256 = (Get-FileHash -LiteralPath $fullNmapPath -Algorithm SHA256).Hash.ToUpperInvariant()
    $dataDirectory = Get-NmapDataDirectory -NmapPath $fullNmapPath -SelectedScripts $SelectedScripts
    if ($dataDirectory.Contains(',')) {
        throw "The Nmap data directory contains a comma and cannot be encoded safely in the explicit NSE file list: $dataDirectory"
    }
    Assert-NmapProcessEnvironmentIsolated
    $processIsolation = Get-NmapProcessIsolation
    $currentSnapshot = Get-NmapDataTreeSnapshot -Path $dataDirectory -SelectedScripts $SelectedScripts
    $dataManifestPath = Join-Path $script:ScopeDirectory 'nmap-data-manifest.json'
    $normalizedScripts = @($SelectedScripts | Sort-Object -Unique)
    $selectedScriptPaths = @($normalizedScripts | ForEach-Object {
        [IO.Path]::GetFullPath((Join-Path (Join-Path $dataDirectory 'scripts') ($_ + '.nse')))
    })
    $ambientUserDataPaths = @(Get-NmapAmbientUserDataPaths)

    if ($Resume) {
        if ([string]::IsNullOrWhiteSpace($script:OriginalNmapDataManifestSha256) -or
            [string]::IsNullOrWhiteSpace($script:OriginalNmapDataTreeSha256) -or
            [string]::IsNullOrWhiteSpace($script:OriginalNmapDataDirectory) -or
            [string]::IsNullOrWhiteSpace($script:OriginalNmapExecutableSha256)) {
            throw 'The original run manifest has no complete hash-bound Nmap executable/data metadata; runs created before Nmap data-tree binding cannot execute or reuse Nmap evidence safely.'
        }
        if (-not (Test-Path -LiteralPath $dataManifestPath -PathType Leaf)) {
            throw 'Resume requires the original scope\nmap-data-manifest.json; refusing to execute or reuse Nmap evidence without its data-tree binding.'
        }
        $dataManifestSha256 = (Get-FileHash -LiteralPath $dataManifestPath -Algorithm SHA256).Hash.ToUpperInvariant()
        if ($dataManifestSha256 -ine $script:OriginalNmapDataManifestSha256) {
            throw "Resume Nmap data-manifest integrity failure: expected $($script:OriginalNmapDataManifestSha256), observed $dataManifestSha256."
        }
        try {
            $baselineManifest = (Read-Utf8File -Path $dataManifestPath) | ConvertFrom-Json
        }
        catch {
            throw "Resume Nmap data-manifest is not valid JSON: $($_.Exception.Message)"
        }
        $baselineScripts = @($baselineManifest.selectedScripts | ForEach-Object { [string]$_ } | Sort-Object -Unique)
        if ([string]$baselineManifest.schemaVersion -ne '1' -or
            [string]$baselineManifest.dataTreeSha256 -notmatch '^[A-Fa-f0-9]{64}$' -or
            [string]$baselineManifest.nmapExecutableSha256 -notmatch '^[A-Fa-f0-9]{64}$') {
            throw 'Resume Nmap data-manifest has invalid or incomplete binding fields.'
        }
        if ([IO.Path]::GetFullPath([string]$baselineManifest.dataDirectory) -ine $dataDirectory -or
            $script:OriginalNmapDataDirectory -ine $dataDirectory) {
            throw "Resume Nmap data directory differs from the original frozen directory: $dataDirectory"
        }
        if ([string]$baselineManifest.nmapExecutableSha256 -ine $nmapSha256 -or
            $script:OriginalNmapExecutableSha256 -ine $nmapSha256) {
            throw 'Resume Nmap executable SHA-256 differs from the original run.'
        }
        if ([string]$baselineManifest.dataTreeSha256 -ine $currentSnapshot.TreeSha256 -or
            $script:OriginalNmapDataTreeSha256 -ine $currentSnapshot.TreeSha256) {
            throw 'Resume Nmap data tree differs from the original hash-bound snapshot.'
        }
        if (($baselineScripts -join "`n") -cne ($normalizedScripts -join "`n")) {
            throw 'Resume selected NSE set differs from the original Nmap data-manifest.'
        }
    }
    else {
        $baselineManifest = [ordered]@{
            schemaVersion = 1
            createdUtc = [DateTime]::UtcNow.ToString('o')
            nmapExecutable = $fullNmapPath
            nmapExecutableSha256 = $nmapSha256
            dataDirectory = $dataDirectory
            dataTreeSha256 = $currentSnapshot.TreeSha256
            fileCount = $currentSnapshot.FileCount
            directoryCount = $currentSnapshot.DirectoryCount
            selectedScripts = $normalizedScripts
            selectedScriptPaths = $selectedScriptPaths
            processIsolationRoot = $processIsolation.Root
            processIsolation = [ordered]@{
                root = $processIsolation.Root
                appData = $processIsolation.AppData
                localAppData = $processIsolation.LocalAppData
                profile = $processIsolation.Profile
                home = $processIsolation.Home
                workingDirectory = $processIsolation.WorkingDirectory
            }
            ambientUserDataPathsChecked = $ambientUserDataPaths
            records = $currentSnapshot.Records
        }
        Write-Utf8File -Path $dataManifestPath -Content ($baselineManifest | ConvertTo-Json -Depth 8)
        $dataManifestSha256 = (Get-FileHash -LiteralPath $dataManifestPath -Algorithm SHA256).Hash.ToUpperInvariant()
    }

    $script:NmapDataBaseline = [pscustomobject]@{
        NmapPath = $fullNmapPath
        NmapSha256 = $nmapSha256
        DataDirectory = $dataDirectory
        DataManifestPath = $dataManifestPath
        DataManifestSha256 = $dataManifestSha256
        DataTreeSha256 = $currentSnapshot.TreeSha256
        FileCount = $currentSnapshot.FileCount
        DirectoryCount = $currentSnapshot.DirectoryCount
        SelectedScripts = $normalizedScripts
        SelectedScriptPaths = $selectedScriptPaths
        ProcessIsolation = $processIsolation
        AmbientUserDataPaths = $ambientUserDataPaths
    }
    $script:NmapDataIntegrityFailed = $false
    $script:Manifest.tools['nmap'] = [ordered]@{
        found = $true
        path = $fullNmapPath
        sha256 = $nmapSha256
        dataDirectory = $dataDirectory
        dataManifest = $dataManifestPath
        dataManifestSha256 = $dataManifestSha256
        dataTreeSha256 = $currentSnapshot.TreeSha256
        dataFileCount = $currentSnapshot.FileCount
        dataDirectoryCount = $currentSnapshot.DirectoryCount
        selectedScripts = $normalizedScripts
        selectedScriptPaths = $selectedScriptPaths
        processIsolationRoot = $processIsolation.Root
        processIsolation = [ordered]@{
            root = $processIsolation.Root
            appData = $processIsolation.AppData
            localAppData = $processIsolation.LocalAppData
            profile = $processIsolation.Profile
            home = $processIsolation.Home
            workingDirectory = $processIsolation.WorkingDirectory
        }
        ambientUserDataPathsChecked = $ambientUserDataPaths
    }
    Write-RunManifest
    Write-Log -Level INFO -Message ("Bound Nmap to {0}; data tree {1} contains {2} regular file(s) and {3} non-reparse directorie(s)." -f
        $dataDirectory, $currentSnapshot.TreeSha256, $currentSnapshot.FileCount, $currentSnapshot.DirectoryCount)
    return $script:NmapDataBaseline
}

function Test-NmapDataTreeIntegrity {
    param([Parameter(Mandatory = $true)][string]$Moment)
    if ($script:NmapDataIntegrityFailed) { return $false }
    try {
        if (-not $script:NmapDataBaseline) {
            throw 'The Nmap data baseline was not initialized.'
        }
        $currentNmapHash = (Get-FileHash -LiteralPath $script:NmapDataBaseline.NmapPath -Algorithm SHA256).Hash.ToUpperInvariant()
        if ($currentNmapHash -ine $script:NmapDataBaseline.NmapSha256) {
            throw 'nmap.exe changed after its baseline was frozen'
        }
        $snapshot = Get-NmapDataTreeSnapshot -Path $script:NmapDataBaseline.DataDirectory -SelectedScripts $script:NmapDataBaseline.SelectedScripts
        if ($snapshot.TreeSha256 -ine $script:NmapDataBaseline.DataTreeSha256 -or
            $snapshot.FileCount -ne $script:NmapDataBaseline.FileCount -or
            $snapshot.DirectoryCount -ne $script:NmapDataBaseline.DirectoryCount) {
            throw ("data-tree drift: expected {0}/{1} files/{2} directories, observed {3}/{4} files/{5} directories" -f
                $script:NmapDataBaseline.DataTreeSha256, $script:NmapDataBaseline.FileCount, $script:NmapDataBaseline.DirectoryCount,
                $snapshot.TreeSha256, $snapshot.FileCount, $snapshot.DirectoryCount)
        }
        return $true
    }
    catch {
        $script:NmapDataIntegrityFailed = $true
        Write-Log -Level ERROR -Message ("Nmap data integrity failed {0}: {1}. Nmap execution and downstream reuse are stopped." -f $Moment, $_.Exception.Message)
        return $false
    }
}

function Invoke-NmapProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$ArgumentList = @(),
        [Parameter(Mandatory = $true)][string]$Name,
        [int]$TimeoutSeconds = $CommandTimeoutSeconds,
        [int[]]$AllowedExitCodes = @(0),
        [switch]$ContinueOnError,
        [string]$DataDirectory,
        [switch]$ValidateFrozenDataTree
    )
    if (@($ArgumentList | Where-Object { $_ -ieq '--datadir' }).Count -gt 0) {
        throw 'Nmap callers must not supply --datadir directly; Invoke-NmapProcess owns the frozen data-directory binding.'
    }
    if ([string]::IsNullOrWhiteSpace($DataDirectory)) {
        $DataDirectory = if ($ValidateFrozenDataTree -and $script:NmapDataBaseline) {
            $script:NmapDataBaseline.DataDirectory
        }
        else {
            Get-NmapDataDirectory -NmapPath $FilePath
        }
    }
    $processIsolation = Get-NmapProcessIsolation
    $environmentValidBefore = Test-NmapProcessEnvironmentIntegrity -Moment ("immediately before {0}" -f $Name) -MarkDataIntegrityFailure:$ValidateFrozenDataTree
    if (-not $environmentValidBefore) {
        $environmentFailure = [pscustomobject]@{ Success = $false; ExitCode = -1; TimedOut = $false; Stdout = ''; Stderr = 'Nmap process-environment integrity validation failed before process start.'; StdoutPath = $null; StderrPath = $null; DataIntegrityValid = $false }
        if ($ContinueOnError) { return $environmentFailure }
        throw "Nmap process-environment integrity validation failed before $Name."
    }
    if ($ValidateFrozenDataTree -and -not (Test-NmapDataTreeIntegrity -Moment ("immediately before {0}" -f $Name))) {
        $dataFailure = [pscustomobject]@{ Success = $false; ExitCode = -1; TimedOut = $false; Stdout = ''; Stderr = 'Nmap data integrity validation failed before process start.'; StdoutPath = $null; StderrPath = $null; DataIntegrityValid = $false }
        if ($ContinueOnError) { return $dataFailure }
        throw "Nmap data integrity validation failed before $Name."
    }
    $nmapArguments = @('--datadir', [IO.Path]::GetFullPath($DataDirectory))
    if ($ValidateFrozenDataTree) { $nmapArguments += '--no-stylesheet' }
    $nmapArguments += @($ArgumentList)
    $environmentOverrides = @{
        APPDATA = $processIsolation.AppData
        LOCALAPPDATA = $processIsolation.LocalAppData
        USERPROFILE = $processIsolation.Profile
        HOME = $processIsolation.Home
    }
    # Always obtain a result so the actual roaming AppData and frozen data tree
    # can be checked even when Nmap itself exits unsuccessfully.
    $result = Invoke-LoggedProcess -FilePath $FilePath -ArgumentList $nmapArguments -Name $Name -TimeoutSeconds $TimeoutSeconds -AllowedExitCodes $AllowedExitCodes -ContinueOnError -WorkingDirectory $processIsolation.WorkingDirectory -ClearEnvironmentVariables @('NMAPDIR', 'NMAP_ARGS', 'NMAP_PRIVILEGED', 'NMAP_UNPRIVILEGED', 'LUA_PATH', 'LUA_CPATH') -EnvironmentOverrides $environmentOverrides
    $environmentValidAfter = Test-NmapProcessEnvironmentIntegrity -Moment ("immediately after {0}" -f $Name) -MarkDataIntegrityFailure:$ValidateFrozenDataTree
    $dataIntegrityValid = $environmentValidAfter
    if ($ValidateFrozenDataTree) {
        $treeIntegrityValid = Test-NmapDataTreeIntegrity -Moment ("immediately after {0}" -f $Name)
        $dataIntegrityValid = $dataIntegrityValid -and $treeIntegrityValid
        if (-not $dataIntegrityValid) {
            for ($argumentIndex = 0; $argumentIndex -lt ($ArgumentList.Count - 1); $argumentIndex++) {
                if ($ArgumentList[$argumentIndex] -ieq '-oA') {
                    $outputBase = [string]$ArgumentList[$argumentIndex + 1]
                    if (-not [string]::IsNullOrWhiteSpace($outputBase)) {
                        Move-NmapOutputAside -BasePath $outputBase
                    }
                    break
                }
            }
        }
    }
    if (-not $dataIntegrityValid) { $result.Success = $false }
    $result | Add-Member -MemberType NoteProperty -Name DataIntegrityValid -Value $dataIntegrityValid -Force
    if (-not $result.Success -and -not $ContinueOnError) {
        throw ("{0} failed with exit code {1}." -f $Name, $result.ExitCode)
    }
    return $result
}

function Save-ToolMetadata {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Path
    )
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $script:Manifest.tools[$Name] = [ordered]@{ found = $false }
        Write-RunManifest
        return
    }
    $versionText = $null
    try {
        $versionResult = Invoke-LoggedProcess -FilePath $Path -ArgumentList @('-version') -Name ("{0}-version" -f $Name) -TimeoutSeconds 30 -AllowedExitCodes @(0, 1, 2) -ContinueOnError
        $versionText = (($versionResult.Stdout + [Environment]::NewLine + $versionResult.Stderr).Trim() -split "`r?`n" | Select-Object -First 3) -join ' | '
    }
    catch { $versionText = $_.Exception.Message }
    $script:Manifest.tools[$Name] = [ordered]@{
        found = $true
        path = $Path
        sha256 = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
        version = $versionText
    }
    Write-RunManifest
}

function Get-NucleiTemplateStatus {
    $requestedPath = [IO.Path]::GetFullPath($NucleiTemplatesDirectory)
    $candidatePaths = @($requestedPath, (Join-Path $requestedPath 'nuclei-templates')) | Select-Object -Unique
    $selectedPath = $requestedPath
    $templateFiles = @()
    foreach ($candidatePath in $candidatePaths) {
        if (-not (Test-Path -LiteralPath $candidatePath -PathType Container)) { continue }
        try {
            $candidateFiles = @(Get-ChildItem -LiteralPath $candidatePath -File -Recurse -ErrorAction Stop |
                Where-Object { $_.Extension -match '^\.ya?ml$' })
            if ($candidateFiles.Count -gt $templateFiles.Count) {
                $selectedPath = $candidatePath
                $templateFiles = $candidateFiles
            }
        }
        catch { }
    }

    $version = $null
    $configPath = $null
    foreach ($candidatePath in @((Join-Path $selectedPath '.templates-config.json'), (Join-Path $requestedPath '.templates-config.json'))) {
        if (-not (Test-Path -LiteralPath $candidatePath -PathType Leaf)) { continue }
        try {
            $templateConfig = (Read-Utf8File -Path $candidatePath) | ConvertFrom-Json
            foreach ($propertyName in @('nuclei-templates-version', 'templates-version', 'template-version', 'version')) {
                $property = $templateConfig.PSObject.Properties[$propertyName]
                if ($property -and -not [string]::IsNullOrWhiteSpace([string]$property.Value)) {
                    $version = [string]$property.Value
                    break
                }
            }
            $configPath = $candidatePath
            break
        }
        catch { }
    }
    if (-not $version) {
        $versionFile = Join-Path $selectedPath '.version'
        if (Test-Path -LiteralPath $versionFile -PathType Leaf) {
            $version = (Read-Utf8File -Path $versionFile).Trim()
            $configPath = $versionFile
        }
    }

    $templateEntries = New-Object System.Collections.Generic.List[System.String]
    $templateTreeSha256 = $null
    $templateHashError = $null
    $templateTreeFileCount = 0
    if ($templateFiles.Count -gt 0) {
        try {
            $selectedPrefix = $selectedPath.TrimEnd([char[]]@('\', '/')) + [IO.Path]::DirectorySeparatorChar
            $templateTreeFiles = @(Get-ChildItem -LiteralPath $selectedPath -File -Recurse -Force -ErrorAction Stop | Where-Object {
                $relativeCandidate = $_.FullName.Substring($selectedPrefix.Length) -replace '\\', '/'
                $relativeCandidate -notmatch '^(?i:\.git)(?:/|$)'
            } | Sort-Object FullName)
            foreach ($templateFile in $templateTreeFiles) {
                $relativeTemplatePath = $templateFile.FullName.Substring($selectedPrefix.Length) -replace '\\', '/'
                $templateHash = (Get-FileHash -LiteralPath $templateFile.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
                [void]$templateEntries.Add(('{0}  {1}' -f $templateHash, $relativeTemplatePath))
            }
            $templateTreeFileCount = $templateEntries.Count
            $templateTreeText = (($templateEntries.ToArray() -join "`n") + "`n")
            $templateTreeSha256 = Get-TextSha256 -Content $templateTreeText
        }
        catch {
            $templateHashError = $_.Exception.Message
            $templateEntries.Clear()
        }
    }

    $writable = $false
    if (Test-Path -LiteralPath $requestedPath -PathType Container) {
        $probePath = Join-Path $requestedPath ('.cptc-write-probe-' + [Guid]::NewGuid().ToString('N'))
        try {
            [IO.File]::WriteAllText($probePath, '', $script:Utf8NoBom)
            Remove-Item -LiteralPath $probePath -Force -ErrorAction Stop
            $writable = $true
        }
        catch {
            if (Test-Path -LiteralPath $probePath) { Remove-Item -LiteralPath $probePath -Force -ErrorAction SilentlyContinue }
        }
    }
    return [pscustomobject]@{
        RequestedPath = $requestedPath
        Path = $selectedPath
        Exists = (Test-Path -LiteralPath $selectedPath -PathType Container)
        Ready = ($templateFiles.Count -gt 0 -and -not $templateHashError)
        TemplateCount = $templateFiles.Count
        TemplateTreeFileCount = $templateTreeFileCount
        TemplateEntries = $templateEntries.ToArray()
        TemplateTreeSha256 = $templateTreeSha256
        TemplateHashError = $templateHashError
        Version = $(if ($version) { $version } else { 'unknown' })
        ConfigPath = $configPath
        Writable = $writable
    }
}

function Save-NucleiTemplateMetadata {
    param([Parameter(Mandatory = $true)]$Status)
    $treeManifestPath = $null
    $treeManifestSha256 = $null
    if ($script:ScopeDirectory) {
        $treeManifestPath = Join-Path $script:ScopeDirectory 'nuclei-template-files.sha256'
        $treeManifestContent = if (@($Status.TemplateEntries).Count -gt 0) {
            ((@($Status.TemplateEntries) -join "`n") + "`n")
        }
        else { '' }
        Write-Utf8File -Path $treeManifestPath -Content $treeManifestContent
        $treeManifestSha256 = (Get-FileHash -LiteralPath $treeManifestPath -Algorithm SHA256).Hash.ToUpperInvariant()
    }
    $script:Manifest.tools['nucleiTemplates'] = [ordered]@{
        ready = [bool]$Status.Ready
        requestedPath = $Status.RequestedPath
        path = $Status.Path
        version = $Status.Version
        templateCount = $Status.TemplateCount
        templateTreeFileCount = $Status.TemplateTreeFileCount
        templateTreeSha256 = $Status.TemplateTreeSha256
        templateFileManifest = $treeManifestPath
        templateFileManifestSha256 = $treeManifestSha256
        templateHashError = $Status.TemplateHashError
        writableByInvokingUser = [bool]$Status.Writable
        configPath = $Status.ConfigPath
    }
    Write-RunManifest
}

function Test-NucleiTemplateTreeStable {
    param([Parameter(Mandatory = $true)]$ExpectedStatus)
    $currentStatus = Get-NucleiTemplateStatus
    if (-not $currentStatus.Ready -or
        $currentStatus.TemplateCount -ne $ExpectedStatus.TemplateCount -or
        $currentStatus.TemplateTreeFileCount -ne $ExpectedStatus.TemplateTreeFileCount -or
        $currentStatus.Path -ine $ExpectedStatus.Path -or
        $currentStatus.TemplateTreeSha256 -ine $ExpectedStatus.TemplateTreeSha256) {
        Write-Log -Level ERROR -Message ("Nuclei template tree changed or became unreadable before/during scanning. Expected {0} YAML template(s), {1} total input file(s), SHA-256 {2}, path {3}; observed {4} YAML template(s), {5} total input file(s), SHA-256 {6}, path {7}." -f
            $ExpectedStatus.TemplateCount, $ExpectedStatus.TemplateTreeFileCount, $ExpectedStatus.TemplateTreeSha256, $ExpectedStatus.Path,
            $currentStatus.TemplateCount, $currentStatus.TemplateTreeFileCount, $currentStatus.TemplateTreeSha256, $currentStatus.Path)
        return $false
    }
    return $true
}

function Install-NucleiTemplates {
    param([Parameter(Mandatory = $true)][string]$NucleiPath)
    if (-not (Test-Path -LiteralPath $NucleiTemplatesDirectory -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $NucleiTemplatesDirectory -Force)
    }
    Write-Log -Level INFO -Message ("Prefetching Nuclei templates for the invoking user into {0}." -f $NucleiTemplatesDirectory)
    $arguments = @('-update-templates', '-update-template-dir', $NucleiTemplatesDirectory, '-disable-update-check', '-no-color')
    Invoke-LoggedProcess -FilePath $NucleiPath -ArgumentList $arguments -Name 'nuclei-prefetch-templates' -TimeoutSeconds $CommandTimeoutSeconds | Out-Null
    $status = Get-NucleiTemplateStatus
    Save-NucleiTemplateMetadata -Status $status
    if (-not $status.Ready) {
        throw "Nuclei reported a successful template update, but no YAML templates were readable under $NucleiTemplatesDirectory."
    }
    if (-not $status.Writable) {
        Write-Log -Level WARN -Message ("Templates are readable but {0} is not writable by the invoking user; future Install updates may require different permissions." -f $status.RequestedPath)
    }
    Write-Log -Level SUCCESS -Message ("Nuclei templates are ready: version {0}, {1} YAML template(s), {2} total input file(s), tree SHA-256 {3}, path {4}." -f $status.Version, $status.TemplateCount, $status.TemplateTreeFileCount, $status.TemplateTreeSha256, $status.Path)
    return $status
}

function Complete-ManagedToolInstall {
    param(
        [Parameter(Mandatory = $true)][string]$StagedDirectory,
        [Parameter(Mandatory = $true)][string]$Destination,
        [Parameter(Mandatory = $true)][string]$ExecutableName,
        [Parameter(Mandatory = $true)][string]$ExpectedName,
        [Parameter(Mandatory = $true)]$InstallManifest
    )
    $stagedFullPath = [IO.Path]::GetFullPath($StagedDirectory).TrimEnd([char[]]@('\', '/'))
    $destinationFullPath = [IO.Path]::GetFullPath($Destination).TrimEnd([char[]]@('\', '/'))
    if ([IO.Path]::GetPathRoot($stagedFullPath) -ine [IO.Path]::GetPathRoot($destinationFullPath)) {
        throw 'The staged tool and final destination must be on the same volume for rollback-safe installation.'
    }
    $destinationParent = Split-Path -Parent $destinationFullPath
    if (-not (Test-Path -LiteralPath $destinationParent -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $destinationParent -Force)
    }
    $backupPath = Join-Path $destinationParent ('.cptc-backup-{0}-{1}' -f (Get-SafeName -Value $ExpectedName), [Guid]::NewGuid().ToString('N'))
    $backupCreated = $false
    $newDestinationCreated = $false
    try {
        if (Test-Path -LiteralPath $destinationFullPath) {
            Move-Item -LiteralPath $destinationFullPath -Destination $backupPath -ErrorAction Stop
            $backupCreated = $true
        }
        Move-Item -LiteralPath $stagedFullPath -Destination $destinationFullPath -ErrorAction Stop
        $newDestinationCreated = $true
        Write-Utf8File -Path (Join-Path $destinationFullPath 'install-manifest.json') -Content ($InstallManifest | ConvertTo-Json -Depth 5)
        $installed = Get-ChildItem -LiteralPath $destinationFullPath -Filter $ExecutableName -File -Recurse -ErrorAction Stop | Select-Object -First 1
        if (-not $installed) { throw "$ExecutableName was not present after the staged installation was moved." }
        if (-not (Test-ManagedToolCandidate -Path $installed.FullName -ExpectedName $ExpectedName -Quiet)) {
            throw 'Post-install executable/manifest SHA-256 validation failed.'
        }
    }
    catch {
        $installFailure = $_
        $rollbackFailures = New-Object System.Collections.Generic.List[System.String]
        if ($newDestinationCreated -and (Test-Path -LiteralPath $destinationFullPath)) {
            try { Remove-Item -LiteralPath $destinationFullPath -Recurse -Force -ErrorAction Stop }
            catch { [void]$rollbackFailures.Add("could not remove the partial replacement: $($_.Exception.Message)") }
        }
        if ($backupCreated -and (Test-Path -LiteralPath $backupPath)) {
            try {
                if (Test-Path -LiteralPath $destinationFullPath) {
                    throw 'the destination still exists after partial-replacement cleanup'
                }
                Move-Item -LiteralPath $backupPath -Destination $destinationFullPath -ErrorAction Stop
                $backupCreated = $false
            }
            catch { [void]$rollbackFailures.Add("could not restore the previous installation: $($_.Exception.Message)") }
        }
        if ($rollbackFailures.Count -gt 0) {
            throw ("Tool installation failed ({0}); rollback also failed: {1}" -f $installFailure.Exception.Message, ($rollbackFailures -join ' | '))
        }
        throw $installFailure
    }

    if ($backupCreated -and (Test-Path -LiteralPath $backupPath)) {
        try {
            Remove-Item -LiteralPath $backupPath -Recurse -Force -ErrorAction Stop
            $backupCreated = $false
        }
        catch {
            Write-Log -Level WARN -Message ("Installed and postvalidated {0}, but could not delete rollback backup {1}: {2}" -f $ExpectedName, $backupPath, $_.Exception.Message)
        }
    }
    return $installed.FullName
}

function Install-GitHubReleaseTool {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Repository,
        [Parameter(Mandatory = $true)][string]$ExecutableName
    )
    if (-not [Environment]::Is64BitOperatingSystem) {
        throw "$Name bootstrap currently supports 64-bit Windows only."
    }
    $apiUrl = 'https://api.github.com/repos/{0}/releases/latest' -f $Repository
    $headers = @{ 'User-Agent' = 'cptc-windows-enumerator'; 'Accept' = 'application/vnd.github+json' }
    Write-Log -Level INFO -Message ("Resolving latest signed release metadata for {0} from {1}." -f $Name, $Repository)
    $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers -UseBasicParsing -Method Get
    $asset = @($release.assets | Where-Object { $_.name -match '(?i)windows_amd64\.zip$' }) | Select-Object -First 1
    if (-not $asset) { throw "No Windows amd64 ZIP asset found for $Repository release $($release.tag_name)." }
    $checksumAsset = @($release.assets | Where-Object { $_.name -match '(?i)(checksums|sha256).*\.txt$' }) | Select-Object -First 1
    if (-not $checksumAsset) { throw "No checksum manifest found for $Repository release $($release.tag_name); refusing unverified install." }

    $safeVersion = Get-SafeName -Value ([string]$release.tag_name)
    $destination = Join-Path (Join-Path $ToolsDirectory $Name) $safeVersion
    $existingExecutable = Join-Path $destination $ExecutableName
    if ((Test-Path -LiteralPath $existingExecutable -PathType Leaf) -and -not $Force) {
        if (Test-ManagedToolCandidate -Path $existingExecutable -ExpectedName $Name) {
            Write-Log -Level INFO -Message ("{0} {1} is already installed and verified at {2}." -f $Name, $release.tag_name, $destination)
            $script:ToolCache[(Get-ToolCacheKey -Name $Name)] = $existingExecutable
            return $existingExecutable
        }
        throw "The existing $Name installation failed manifest/hash validation. Rerun Install with -Force to replace it."
    }

    $stagingRoot = Join-Path $ToolsDirectory ('.staging-' + [Guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $stagingRoot -Force)
    try {
        $archivePath = Join-Path $stagingRoot ([string]$asset.name)
        $checksumResponse = Invoke-WebRequest -Uri $checksumAsset.browser_download_url -Headers $headers -UseBasicParsing
        $checksumText = [string]$checksumResponse.Content
        # Built by concatenation, not -f: the format operator reads the {64}
        # regex quantifier as placeholder index 64 and throws, which would
        # break every release install before the download starts.
        $pattern = '(?im)^([a-f0-9]{64})\s+\*?' + [regex]::Escape([string]$asset.name) + '\s*$'
        $checksumMatch = [regex]::Match($checksumText, $pattern)
        if (-not $checksumMatch.Success) { throw "Checksum for $($asset.name) was not present in $($checksumAsset.name)." }
        $expectedHash = $checksumMatch.Groups[1].Value.ToUpperInvariant()

        Write-Log -Level INFO -Message ("Downloading {0} from official GitHub release asset {1}." -f $Name, $asset.name)
        Invoke-WebRequest -Uri $asset.browser_download_url -Headers $headers -UseBasicParsing -OutFile $archivePath
        $actualHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToUpperInvariant()
        if ($actualHash -ne $expectedHash) {
            throw "SHA-256 mismatch for $($asset.name): expected $expectedHash, received $actualHash."
        }
        Write-Log -Level SUCCESS -Message ("Verified SHA-256 {0} for {1}." -f $actualHash, $asset.name)

        $expanded = Join-Path $stagingRoot 'expanded'
        Expand-Archive -LiteralPath $archivePath -DestinationPath $expanded -Force
        $executable = Get-ChildItem -LiteralPath $expanded -Filter $ExecutableName -File -Recurse | Select-Object -First 1
        if (-not $executable) { throw "$ExecutableName was not present in $($asset.name)." }
        if ((Test-Path -LiteralPath $destination) -and -not $Force) { throw "Destination exists: $destination" }
        $parent = Split-Path -Parent $destination
        if (-not (Test-Path -LiteralPath $parent)) { [void](New-Item -ItemType Directory -Path $parent -Force) }
        $signature = Get-AuthenticodeSignature -LiteralPath $executable.FullName
        $installManifest = [ordered]@{
            name = $Name
            repository = $Repository
            release = [string]$release.tag_name
            asset = [string]$asset.name
            archiveSha256 = $actualHash
            executableSha256 = (Get-FileHash -LiteralPath $executable.FullName -Algorithm SHA256).Hash
            authenticodeStatus = [string]$signature.Status
            installedUtc = [DateTime]::UtcNow.ToString('o')
        }
        $installedPath = Complete-ManagedToolInstall -StagedDirectory $expanded -Destination $destination -ExecutableName $ExecutableName -ExpectedName $Name -InstallManifest $installManifest
        $script:ToolCache[(Get-ToolCacheKey -Name $Name)] = $installedPath
        Write-Log -Level SUCCESS -Message ("Installed {0} {1} to {2}." -f $Name, $release.tag_name, $destination)
        return $installedPath
    }
    finally {
        if (Test-Path -LiteralPath $stagingRoot) { Remove-Item -LiteralPath $stagingRoot -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

function Invoke-InstallAction {
    $stageErrorStart = $script:ErrorCount
    $executedInstallCount = 0
    $declinedInstallCount = 0
    Set-StageStatus -Name 'install' -Status 'running'
    if (-not (Test-Path -LiteralPath $ToolsDirectory)) { [void](New-Item -ItemType Directory -Path $ToolsDirectory -Force) }
    foreach ($toolName in $InstallTool) {
        if (-not $script:RootCmdlet.ShouldProcess($toolName, 'Install enumeration tool')) {
            $declinedInstallCount++
            continue
        }
        $executedInstallCount++
        try {
            switch ($toolName.ToLowerInvariant()) {
                'nmap' {
                    $existing = Find-Tool -Name 'nmap.exe'
                    if ($existing -and -not $Force) {
                        $existingVersion = Invoke-NmapProcess -FilePath $existing -ArgumentList @('--version') -Name 'verify-existing-nmap-version' -TimeoutSeconds 30
                        if (-not (Test-NpcapAvailable)) {
                            throw 'Nmap is present, but Npcap/NPF was not detected. Install the current official Nmap+Npcap bundle from https://nmap.org/download.html.'
                        }
                        Write-Log -Level INFO -Message ("Nmap is already installed and executable at {0}: {1}" -f $existing, (@($existingVersion.Stdout -split "`r?`n")[0]))
                        break
                    }
                    $winget = Find-Tool -Name 'winget.exe'
                    if (-not $winget) {
                        throw 'winget was not found. Install Nmap from https://nmap.org/download.html and include Npcap, then rerun Doctor.'
                    }
                    Invoke-LoggedProcess -FilePath $winget -ArgumentList @('install', '--id', 'Insecure.Nmap', '--exact', '--accept-source-agreements', '--accept-package-agreements') -Name 'install-nmap' -TimeoutSeconds 1800 | Out-Null
                    [void]$script:ToolCache.Remove('nmap')
                    $installedNmap = Find-Tool -Name 'nmap.exe'
                    if (-not $installedNmap) {
                        throw 'Winget exited successfully, but nmap.exe could not be resolved. Install the current official Nmap+Npcap bundle from https://nmap.org/download.html.'
                    }
                    $installedVersion = Invoke-NmapProcess -FilePath $installedNmap -ArgumentList @('--version') -Name 'verify-installed-nmap-version' -TimeoutSeconds 30
                    if (-not (Test-NpcapAvailable)) {
                        throw 'Winget installed nmap.exe, but Npcap/NPF was not detected. Install the current official Nmap+Npcap bundle from https://nmap.org/download.html.'
                    }
                    Write-Log -Level SUCCESS -Message ("Verified installed Nmap at {0}: {1}; Npcap/NPF is available." -f $installedNmap, (@($installedVersion.Stdout -split "`r?`n")[0]))
                    Write-Log -Level WARN -Message 'The Winget Insecure.Nmap package has historically lagged upstream (including a 7.80 package). Verify `nmap --version`; install the current Nmap and Npcap interactively from https://nmap.org/download.html when Winget is behind.'
                }
                'httpx' { Install-GitHubReleaseTool -Name 'httpx' -Repository 'projectdiscovery/httpx' -ExecutableName 'httpx.exe' | Out-Null }
                'nuclei' {
                    $installedNuclei = Install-GitHubReleaseTool -Name 'nuclei' -Repository 'projectdiscovery/nuclei' -ExecutableName 'nuclei.exe'
                    Install-NucleiTemplates -NucleiPath $installedNuclei | Out-Null
                }
                'ffuf' { Install-GitHubReleaseTool -Name 'ffuf' -Repository 'ffuf/ffuf' -ExecutableName 'ffuf.exe' | Out-Null }
            }
        }
        catch {
            Write-Log -Level ERROR -Message ("Could not install {0}: {1}" -f $toolName, $_.Exception.Message)
        }
    }
    $installStatus = if ($executedInstallCount -eq 0 -and $WhatIfPreference) {
        'planned'
    }
    elseif ($executedInstallCount -eq 0 -and $declinedInstallCount -gt 0) {
        'skipped'
    }
    elseif ($script:ErrorCount -gt $stageErrorStart -or $declinedInstallCount -gt 0) {
        'partial'
    }
    else {
        'complete'
    }
    $installDetail = if ($installStatus -eq 'planned') {
        'WhatIf preview; no installation executed'
    }
    elseif ($installStatus -eq 'skipped') {
        "All $declinedInstallCount installation request(s) were declined"
    }
    else {
        "Executed $executedInstallCount installation request(s); declined $declinedInstallCount"
    }
    Set-StageStatus -Name 'install' -Status $installStatus -Detail $installDetail
}

function Invoke-DoctorAction {
    Set-StageStatus -Name 'doctor' -Status 'running'
    $checks = New-Object System.Collections.Generic.List[System.Object]
    $isAdministrator = Get-IsAdministrator
    $npcap = Test-NpcapAvailable
    [void]$checks.Add([pscustomobject]@{ Check = 'PowerShell'; Status = 'PASS'; Detail = $PSVersionTable.PSVersion.ToString() })
    [void]$checks.Add([pscustomobject]@{ Check = 'Language mode'; Status = $(if ($ExecutionContext.SessionState.LanguageMode -eq 'FullLanguage') { 'PASS' } else { 'FAIL' }); Detail = ('{0}; FullLanguage is required' -f $ExecutionContext.SessionState.LanguageMode) })
    [void]$checks.Add([pscustomobject]@{ Check = 'Administrator'; Status = $(if ($isAdministrator) { 'PASS' } else { 'WARN' }); Detail = $(if ($isAdministrator) { 'Raw scans available' } else { 'Nmap will use TCP connect scans' }) })
    [void]$checks.Add([pscustomobject]@{ Check = 'Npcap'; Status = $(if ($npcap) { 'PASS' } else { 'WARN' }); Detail = $(if ($npcap) { 'Npcap/NPF service installed' } else { 'Install Npcap for SYN, UDP, and OS scans' }) })

    $toolSpecs = @(
        @{ Name = 'nmap'; Command = 'nmap.exe'; Required = $true; VersionArgs = @('--version'); VersionPattern = '(?im)^Nmap version\s+\d+(?:\.\d+)' },
        @{ Name = 'httpx'; Command = 'httpx.exe'; Required = $false; VersionArgs = @('-version'); VersionPattern = '(?i)(?:httpx|current\s+version)[^\r\n]*v?\d+(?:\.\d+)+' },
        @{ Name = 'nuclei'; Command = 'nuclei.exe'; Required = $false; VersionArgs = @('-version'); VersionPattern = '(?i)(?:nuclei|engine\s+version)[^\r\n]*v?\d+(?:\.\d+)+' },
        @{ Name = 'ffuf'; Command = 'ffuf.exe'; Required = $false; VersionArgs = @('-V'); VersionPattern = '(?i)ffuf[^\r\n]*(?:version\s*:\s*)?v?\d+(?:\.\d+)+' }
    )
    $duplicateToolSpecs = @($toolSpecs | Group-Object Name | Where-Object { $_.Count -gt 1 })
    if ($duplicateToolSpecs.Count -gt 0) {
        throw ("Doctor has duplicate tool check names: {0}" -f (@($duplicateToolSpecs.Name) -join ', '))
    }
    foreach ($spec in $toolSpecs) {
        $path = Find-Tool -Name $spec.Command
        $toolUsable = [bool]$path
        $status = if ($path) { 'PASS' } elseif ($spec.Required) { 'FAIL' } else { 'WARN' }
        $detail = if ($path) { $path } else { 'Not found' }
        $versionText = $null
        $nmapDataDirectory = $null
        $nmapDataSnapshot = $null
        if ($path) {
            try {
                if ($spec.Name -eq 'nmap') {
                    $nmapDataDirectory = Get-NmapDataDirectory -NmapPath $path -SelectedScripts @(Get-SelectedNmapScripts)
                    $nmapDataSnapshot = Get-NmapDataTreeSnapshot -Path $nmapDataDirectory -SelectedScripts @(Get-SelectedNmapScripts)
                    $versionResult = Invoke-NmapProcess -FilePath $path -ArgumentList $spec.VersionArgs -Name 'doctor-nmap-version' -TimeoutSeconds 30 -ContinueOnError -DataDirectory $nmapDataDirectory
                }
                else {
                    $versionResult = Invoke-LoggedProcess -FilePath $path -ArgumentList $spec.VersionArgs -Name ("doctor-{0}-version" -f $spec.Name) -TimeoutSeconds 30 -ContinueOnError
                }
                $versionText = ($versionResult.Stdout + [Environment]::NewLine + $versionResult.Stderr).Trim()
                if (-not $versionResult.Success) {
                    $status = 'FAIL'
                    $toolUsable = $false
                    $failureDetail = ($versionResult.Stderr.Trim() -split "`r?`n" | Select-Object -First 1)
                    if (-not $failureDetail) { $failureDetail = "exit code $($versionResult.ExitCode)" }
                    $detail += '; version probe failed: ' + $failureDetail
                }
                elseif ($versionText -notmatch $spec.VersionPattern) {
                    $status = 'FAIL'
                    $toolUsable = $false
                    $detail += '; version probe returned exit 0 but no recognizable ' + $spec.Name + ' version string'
                }
                else {
                    $versionSummary = @($versionText -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 3) -join ' | '
                    if ($versionSummary) { $detail += '; ' + $versionSummary }
                }
                if ($spec.Name -eq 'nmap') {
                    $fileVersion = [Diagnostics.FileVersionInfo]::GetVersionInfo($path).ProductVersion
                    if ($fileVersion) { $detail += '; file version ' + $fileVersion }
                    if ($nmapDataSnapshot) { $detail += '; data tree SHA-256 ' + $nmapDataSnapshot.TreeSha256 }
                }
                if ($spec.Name -eq 'nmap' -and $toolUsable -and ($fileVersion -match '^7\.80(?:\.|$)' -or $versionText -match 'Nmap version 7\.80(?:\s|$)')) {
                    $status = 'WARN'
                    $detail += '; Winget 7.80 is stale - use the current official Nmap+Npcap installer from nmap.org/download.html'
                }
            }
            catch {
                $status = 'FAIL'
                $toolUsable = $false
                $detail += '; version probe could not run: ' + $_.Exception.Message
            }
        }
        [void]$checks.Add([pscustomobject]@{ Check = $spec.Name; Status = $status; Detail = $detail })
        if ($path) {
            $script:Manifest.tools[$spec.Name] = [ordered]@{
                found = $true
                usable = $toolUsable
                path = $path
                sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
                version = $versionText
            }
            if ($spec.Name -eq 'nmap' -and $nmapDataDirectory -and $nmapDataSnapshot) {
                $script:Manifest.tools[$spec.Name].dataDirectory = $nmapDataDirectory
                $script:Manifest.tools[$spec.Name].dataTreeSha256 = $nmapDataSnapshot.TreeSha256
                $script:Manifest.tools[$spec.Name].dataFileCount = $nmapDataSnapshot.FileCount
            }
        }
        else {
            $script:Manifest.tools[$spec.Name] = [ordered]@{ found = $false }
        }
    }

    $templateStatus = Get-NucleiTemplateStatus
    Save-NucleiTemplateMetadata -Status $templateStatus
    if ($templateStatus.Ready) {
        $templateCheckStatus = if ($templateStatus.Writable) { 'PASS' } else { 'WARN' }
        $templateDetail = 'version {0}; {1} YAML template(s); {2} total input file(s); tree SHA-256 {3}; {4}; writable={5}' -f $templateStatus.Version, $templateStatus.TemplateCount, $templateStatus.TemplateTreeFileCount, $templateStatus.TemplateTreeSha256, $templateStatus.Path, $templateStatus.Writable
    }
    else {
        $templateCheckStatus = if ($EnableNuclei) { 'FAIL' } else { 'WARN' }
        $templateDetail = "No readable local templates found under $NucleiTemplatesDirectory; run -Action Install -InstallTool nuclei."
    }
    [void]$checks.Add([pscustomobject]@{ Check = 'nuclei templates'; Status = $templateCheckStatus; Detail = $templateDetail })

    $hasScopeInput = (@($Target).Count -gt 0) -or $TargetsFile -or $ConfigPath
    if ($hasScopeInput) {
        try {
            $scope = Resolve-Scope
            [void]$checks.Add([pscustomobject]@{ Check = 'Scope'; Status = 'PASS'; Detail = ("{0} target(s), SHA-256 {1}" -f $scope.Count, $scope.Sha256) })
        }
        catch {
            [void]$checks.Add([pscustomobject]@{ Check = 'Scope'; Status = 'FAIL'; Detail = $_.Exception.Message })
            $script:HadErrors = $true
        }
    }
    else {
        [void]$checks.Add([pscustomobject]@{ Check = 'Scope'; Status = 'WARN'; Detail = 'No scope input supplied; tool checks only' })
    }

    $duplicateChecks = @($checks | Group-Object Check | Where-Object { $_.Count -gt 1 })
    if ($duplicateChecks.Count -gt 0) {
        throw ("Doctor produced duplicate check names: {0}" -f (@($duplicateChecks.Name) -join ', '))
    }
    $doctorPath = Join-Path $script:RunRoot 'doctor.json'
    Write-Utf8File -Path $doctorPath -Content ($checks | ConvertTo-Json -Depth 5)
    Write-Host ''
    $checks | Format-Table -AutoSize | Out-Host
    $failed = @($checks | Where-Object { $_.Status -eq 'FAIL' })
    if ($failed.Count -gt 0) { $script:HadErrors = $true }
    $status = if ($failed.Count -gt 0) { 'partial' } else { 'complete' }
    Set-StageStatus -Name 'doctor' -Status $status -Detail ("Results: {0}" -f $doctorPath)
}

function New-AllowedAddressSet {
    param([string[]]$Addresses)
    $set = New-Object -TypeName 'System.Collections.Generic.HashSet[System.String]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($address in @($Addresses)) {
        $parsedAddress = $null
        if ([Net.IPAddress]::TryParse(([string]$address).Trim(), [ref]$parsedAddress) -and
            $parsedAddress.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork) {
            [void]$set.Add($parsedAddress.ToString())
        }
    }
    return ,$set
}

function Get-NmapXmlDocument {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [switch]$RequireSuccessfulRun
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf) -or (Get-Item -LiteralPath $Path).Length -eq 0) { return $null }
    try {
        $settings = New-Object System.Xml.XmlReaderSettings
        # Nmap emits a standard local DOCTYPE declaration. Ignore its DTD while
        # keeping both resolvers null so no external entity can be retrieved.
        $settings.DtdProcessing = [System.Xml.DtdProcessing]::Ignore
        $settings.XmlResolver = $null
        $reader = [System.Xml.XmlReader]::Create($Path, $settings)
        try {
            $document = New-Object System.Xml.XmlDocument
            $document.XmlResolver = $null
            $document.Load($reader)
        }
        finally {
            $reader.Dispose()
        }
    }
    catch {
        Write-Log -Level WARN -Message ("Could not parse Nmap XML {0}: {1}" -f $Path, $_.Exception.Message)
        return $null
    }

    if (-not $document.SelectSingleNode('/nmaprun')) {
        Write-Log -Level WARN -Message ("Rejected Nmap XML without an nmaprun root: {0}" -f $Path)
        return $null
    }
    if ($RequireSuccessfulRun) {
        $finishedNode = $document.SelectSingleNode('/nmaprun/runstats/finished')
        $exitAttribute = if ($finishedNode) { $finishedNode.Attributes.GetNamedItem('exit') } else { $null }
        if (-not $exitAttribute -or [string]$exitAttribute.Value -ine 'success') {
            $exitValue = if ($exitAttribute) { [string]$exitAttribute.Value } else { '<missing>' }
            Write-Log -Level WARN -Message ("Rejected incomplete/failed Nmap XML {0}; runstats finished exit={1}." -f $Path, $exitValue)
            return $null
        }
    }
    Write-Output -NoEnumerate $document
}

function Test-NmapXmlSuccess {
    param([Parameter(Mandatory = $true)][string]$Path)
    return $null -ne (Get-NmapXmlDocument -Path $Path -RequireSuccessfulRun)
}

function Read-NmapXml {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$AllowedAddresses
    )
    $document = Get-NmapXmlDocument -Path $Path -RequireSuccessfulRun
    if ($null -eq $document) { return @() }
    $allowedSet = New-AllowedAddressSet -Addresses $AllowedAddresses

    $records = New-Object System.Collections.Generic.List[System.Object]
    $rejectedAddresses = New-Object -TypeName 'System.Collections.Generic.HashSet[System.String]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($hostNode in @($document.SelectNodes('/nmaprun/host'))) {
        $addressNode = $hostNode.SelectSingleNode('address[@addrtype="ipv4"]')
        if (-not $addressNode) { continue }
        $parsedAddress = $null
        if (-not [Net.IPAddress]::TryParse([string]$addressNode.GetAttribute('addr'), [ref]$parsedAddress) -or
            $parsedAddress.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork) {
            continue
        }
        $address = $parsedAddress.ToString()
        if (-not $allowedSet.Contains($address)) {
            [void]$rejectedAddresses.Add($address)
            continue
        }
        $hostName = ''
        $hostNameNode = $hostNode.SelectSingleNode('hostnames/hostname[1]')
        if ($hostNameNode) { $hostName = [string]$hostNameNode.GetAttribute('name') }
        # smb-os-discovery, smb-enum-shares, smb-protocols, smb2-security-mode
        # and smb2-time are hostrule scripts: nmap writes their output under
        # <host><hostscript>, not under a port, so a port-only walk discards
        # every SMB host finding (shares, OS, signing posture).
        $hostScriptOutput = New-Object System.Collections.Generic.List[System.String]
        foreach ($hostScriptNode in @($hostNode.SelectNodes('hostscript/script'))) {
            if ($hostScriptNode) {
                [void]$hostScriptOutput.Add(('{0}: {1}' -f [string]$hostScriptNode.GetAttribute('id'), [string]$hostScriptNode.GetAttribute('output')))
            }
        }
        $hostScripts = ($hostScriptOutput -join ' | ')
        $osMatch = ''
        $osMatchNode = $hostNode.SelectSingleNode('os/osmatch[1]')
        if ($osMatchNode) {
            $osMatch = ('{0} ({1}%)' -f [string]$osMatchNode.GetAttribute('name'), [string]$osMatchNode.GetAttribute('accuracy'))
        }
        foreach ($portNode in @($hostNode.SelectNodes('ports/port'))) {
            $stateNode = $portNode.SelectSingleNode('state')
            if (-not $stateNode -or [string]$stateNode.GetAttribute('state') -notmatch '^open') { continue }
            $scriptOutput = New-Object System.Collections.Generic.List[System.String]
            foreach ($scriptNode in @($portNode.SelectNodes('script'))) {
                if ($scriptNode) { [void]$scriptOutput.Add(('{0}: {1}' -f [string]$scriptNode.GetAttribute('id'), [string]$scriptNode.GetAttribute('output'))) }
            }
            $serviceNode = $portNode.SelectSingleNode('service')
            [void]$records.Add([pscustomobject]@{
                Address = $address
                HostName = $hostName
                Protocol = [string]$portNode.GetAttribute('protocol')
                Port = [int]$portNode.GetAttribute('portid')
                State = [string]$stateNode.GetAttribute('state')
                Reason = [string]$stateNode.GetAttribute('reason')
                Service = $(if ($serviceNode) { [string]$serviceNode.GetAttribute('name') } else { '' })
                Product = $(if ($serviceNode) { [string]$serviceNode.GetAttribute('product') } else { '' })
                Version = $(if ($serviceNode) { [string]$serviceNode.GetAttribute('version') } else { '' })
                ExtraInfo = $(if ($serviceNode) { [string]$serviceNode.GetAttribute('extrainfo') } else { '' })
                Tunnel = $(if ($serviceNode) { [string]$serviceNode.GetAttribute('tunnel') } else { '' })
                Scripts = ($scriptOutput -join ' | ')
                HostScripts = $hostScripts
                OsMatch = $osMatch
                SourceXml = $Path
            })
        }
    }
    if ($rejectedAddresses.Count -gt 0) {
        Write-Log -Level WARN -Message ("Discarded {0} out-of-scope address(es) while parsing {1}: {2}" -f $rejectedAddresses.Count, $Path, (($rejectedAddresses | Sort-Object) -join ', '))
    }
    return $records.ToArray()
}

function Merge-NmapInventory {
    param(
        [object[]]$Baseline,
        [object[]]$Enrichment
    )
    $recordMap = @{}
    foreach ($record in @($Baseline)) {
        $key = '{0}|{1}|{2}' -f $record.Address, $record.Protocol, $record.Port
        $recordMap[$key] = $record
    }
    foreach ($record in @($Enrichment)) {
        $key = '{0}|{1}|{2}' -f $record.Address, $record.Protocol, $record.Port
        if (-not $recordMap.ContainsKey($key)) {
            $recordMap[$key] = $record
            continue
        }
        $existing = $recordMap[$key]
        foreach ($propertyName in @('HostName', 'State', 'Reason', 'Service', 'Product', 'Version', 'ExtraInfo', 'Tunnel', 'HostScripts', 'OsMatch')) {
            $newValue = [string]$record.$propertyName
            if (-not [string]::IsNullOrWhiteSpace($newValue)) { $existing.$propertyName = $newValue }
        }
        $scriptValues = @([string]$existing.Scripts, [string]$record.Scripts) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
        $existing.Scripts = $scriptValues -join ' | '
        $sourceValues = New-Object System.Collections.Generic.List[System.String]
        foreach ($sourceText in @([string]$existing.SourceXml, [string]$record.SourceXml)) {
            foreach ($sourceValue in @($sourceText -split ';\s*')) {
                if (-not [string]::IsNullOrWhiteSpace($sourceValue) -and -not $sourceValues.Contains($sourceValue.Trim())) {
                    [void]$sourceValues.Add($sourceValue.Trim())
                }
            }
        }
        $existing.SourceXml = $sourceValues.ToArray() -join '; '
    }
    return @($recordMap.Values | Sort-Object Address, Protocol, Port)
}

function Test-Checkpoint {
    param([Parameter(Mandatory = $true)][string]$XmlPath)
    if (-not $Resume -or -not $script:ResumeScopeMatches -or -not $script:CheckpointIntegrityVerified) { return $false }
    return Test-NmapXmlSuccess -Path $XmlPath
}

function Move-NmapOutputAside {
    param([Parameter(Mandatory = $true)][string]$BasePath)
    $suffix = '.stale_{0}_{1}' -f [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'), ([Guid]::NewGuid().ToString('N').Substring(0, 8))
    foreach ($extension in @('.xml', '.nmap', '.gnmap')) {
        $path = $BasePath + $extension
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $destination = $path + $suffix
            Move-Item -LiteralPath $path -Destination $destination -Force
            Write-Log -Level WARN -Message ("Preserved non-reusable Nmap output as {0}." -f $destination)
        }
    }
}

function Assert-UnverifiedEvidenceQuarantineDirectory {
    param([Parameter(Mandatory = $true)][string]$Path)
    try {
        Assert-NmapPathAncestorsNonReparse -Path $Path
    }
    catch {
        throw ("Unverified evidence quarantine rejected an unsafe, missing, or reparse-point directory chain at {0}: {1}" -f
            $Path, $_.Exception.Message)
    }
}

function Reset-UnverifiedResumeEvidence {
    if (-not $Resume -or $script:ExistingChecksumStatus -ne 'missing') { return }

    # If quarantine fails partway through, do not bless any surviving stale
    # artifacts with a newly generated checksum baseline in the finalizer.
    $script:SuppressArtifactHashFinalization = $true
    foreach ($sourceDirectory in @($script:RunRoot, $script:LogDirectory, $script:RawDirectory, $script:NormalizedDirectory, $script:ReportDirectory, $script:ScopeDirectory)) {
        Assert-UnverifiedEvidenceQuarantineDirectory -Path $sourceDirectory
    }
    $runParent = [IO.Path]::GetFullPath((Split-Path -Parent $script:RunRoot))
    Assert-UnverifiedEvidenceQuarantineDirectory -Path $runParent
    $runName = Get-SafeName -Value (Split-Path -Leaf $script:RunRoot)
    $quarantineParent = [IO.Path]::GetFullPath((Join-Path $runParent '.cptc-unverified-resume'))
    if (Test-Path -LiteralPath $quarantineParent) {
        Assert-UnverifiedEvidenceQuarantineDirectory -Path $quarantineParent
    }
    else {
        [void](New-Item -ItemType Directory -Path $quarantineParent -ErrorAction Stop)
        Assert-UnverifiedEvidenceQuarantineDirectory -Path $quarantineParent
    }
    $quarantineRoot = [IO.Path]::GetFullPath((Join-Path $quarantineParent ('{0}_{1}_{2}' -f
        $runName, [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'), ([Guid]::NewGuid().ToString('N').Substring(0, 8)))
    ))
    if (Test-Path -LiteralPath $quarantineRoot) { throw "Refusing preexisting unverified evidence quarantine path: $quarantineRoot" }
    [void](New-Item -ItemType Directory -Path $quarantineRoot -ErrorAction Stop)
    Assert-UnverifiedEvidenceQuarantineDirectory -Path $quarantineRoot
    $movedEntryCount = 0

    foreach ($directoryRecord in @(
        [pscustomobject]@{ Path = $script:RawDirectory; Name = 'raw' },
        [pscustomobject]@{ Path = $script:NormalizedDirectory; Name = 'normalized' },
        [pscustomobject]@{ Path = $script:ReportDirectory; Name = 'report' }
    )) {
        $destinationDirectory = Join-Path $quarantineRoot $directoryRecord.Name
        [void](New-Item -ItemType Directory -Path $destinationDirectory -ErrorAction Stop)
        Assert-UnverifiedEvidenceQuarantineDirectory -Path $destinationDirectory
        foreach ($entry in @(Get-ChildItem -LiteralPath $directoryRecord.Path -Force -ErrorAction Stop)) {
            Assert-NmapRegularNonReparseItem -Item $entry -ExpectedType $(if ($entry.PSIsContainer) { 'Directory' } else { 'File' })
            Move-Item -LiteralPath $entry.FullName -Destination $destinationDirectory -Force -ErrorAction Stop
            $movedEntryCount++
        }
    }

    $logQuarantine = Join-Path $quarantineRoot 'logs-historical'
    [void](New-Item -ItemType Directory -Path $logQuarantine -ErrorAction Stop)
    Assert-UnverifiedEvidenceQuarantineDirectory -Path $logQuarantine
    $currentLogPaths = New-Object -TypeName 'System.Collections.Generic.HashSet[System.String]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($currentLogPath in @($script:RunnerLog, $script:EventLog, $script:TranscriptPath)) {
        if (-not [string]::IsNullOrWhiteSpace($currentLogPath)) {
            [void]$currentLogPaths.Add([IO.Path]::GetFullPath($currentLogPath))
        }
    }
    foreach ($logEntry in @(Get-ChildItem -LiteralPath $script:LogDirectory -Force -ErrorAction Stop)) {
        $fullLogPath = [IO.Path]::GetFullPath($logEntry.FullName)
        if ($currentLogPaths.Contains($fullLogPath)) { continue }
        Assert-NmapRegularNonReparseItem -Item $logEntry -ExpectedType $(if ($logEntry.PSIsContainer) { 'Directory' } else { 'File' })
        Move-Item -LiteralPath $logEntry.FullName -Destination $logQuarantine -Force -ErrorAction Stop
        $movedEntryCount++
    }

    $preservedScopeNames = New-Object -TypeName 'System.Collections.Generic.HashSet[System.String]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
    [void]$preservedScopeNames.Add('targets.txt')
    [void]$preservedScopeNames.Add('resolution-map.json')
    foreach ($boundScopePath in @(
        (Join-Path $script:ScopeDirectory 'targets.txt'),
        (Join-Path $script:ScopeDirectory 'resolution-map.json')
    )) {
        $boundScopeItem = Get-Item -LiteralPath $boundScopePath -Force -ErrorAction Stop
        Assert-NmapRegularNonReparseItem -Item $boundScopeItem -ExpectedType File
    }
    $nmapDataManifestPath = Join-Path $script:ScopeDirectory 'nmap-data-manifest.json'
    if (-not [string]::IsNullOrWhiteSpace($script:OriginalNmapDataManifestSha256) -and
        (Test-Path -LiteralPath $nmapDataManifestPath -PathType Leaf)) {
        $nmapDataManifestItem = Get-Item -LiteralPath $nmapDataManifestPath -Force -ErrorAction Stop
        Assert-NmapRegularNonReparseItem -Item $nmapDataManifestItem -ExpectedType File
        $currentNmapManifestHash = (Get-FileHash -LiteralPath $nmapDataManifestPath -Algorithm SHA256).Hash.ToUpperInvariant()
        if ($currentNmapManifestHash -eq $script:OriginalNmapDataManifestSha256) {
            [void]$preservedScopeNames.Add('nmap-data-manifest.json')
        }
    }
    if ($EnableFfuf -and -not [string]::IsNullOrWhiteSpace($Wordlist)) {
        try {
            $requestedWordlistPath = [IO.Path]::GetFullPath((Get-FullPath -Path $Wordlist))
            $runWordlistPath = [IO.Path]::GetFullPath((Join-Path $script:ScopeDirectory 'ffuf-wordlist.txt'))
            if ($requestedWordlistPath -ieq $runWordlistPath) {
                # This file is current, explicitly supplied input. New-FrozenFfufWordlist
                # will lock, hash, and refreeze it before any ffuf process starts.
                [void]$preservedScopeNames.Add('ffuf-wordlist.txt')
            }
        }
        catch { }
    }

    $scopeQuarantine = Join-Path $quarantineRoot 'scope-derived'
    [void](New-Item -ItemType Directory -Path $scopeQuarantine -ErrorAction Stop)
    Assert-UnverifiedEvidenceQuarantineDirectory -Path $scopeQuarantine
    foreach ($entry in @(Get-ChildItem -LiteralPath $script:ScopeDirectory -Force -ErrorAction Stop)) {
        if ($preservedScopeNames.Contains($entry.Name)) { continue }
        Move-Item -LiteralPath $entry.FullName -Destination $scopeQuarantine -Force -ErrorAction Stop
        $movedEntryCount++
    }

    $rootQuarantine = Join-Path $quarantineRoot 'root-derived'
    [void](New-Item -ItemType Directory -Path $rootQuarantine -ErrorAction Stop)
    Assert-UnverifiedEvidenceQuarantineDirectory -Path $rootQuarantine
    $preservedRootNames = New-Object -TypeName 'System.Collections.Generic.HashSet[System.String]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($preservedName in @('run-manifest.json', '.cptc-run.lock', (Split-Path -Leaf $script:ManifestPath))) {
        if (-not [string]::IsNullOrWhiteSpace($preservedName)) { [void]$preservedRootNames.Add($preservedName) }
    }
    foreach ($rootFile in @(Get-ChildItem -LiteralPath $script:RunRoot -Force -File -ErrorAction Stop)) {
        Assert-NmapRegularNonReparseItem -Item $rootFile -ExpectedType File
        if ($preservedRootNames.Contains($rootFile.Name)) { continue }
        Move-Item -LiteralPath $rootFile.FullName -Destination $rootQuarantine -Force -ErrorAction Stop
        $movedEntryCount++
    }
    $preservedRootDirectories = New-Object -TypeName 'System.Collections.Generic.HashSet[System.String]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($preservedDirectory in @($script:LogDirectory, $script:RawDirectory, $script:NormalizedDirectory, $script:ReportDirectory, $script:ScopeDirectory)) {
        [void]$preservedRootDirectories.Add((Split-Path -Leaf $preservedDirectory))
    }
    foreach ($rootDirectory in @(Get-ChildItem -LiteralPath $script:RunRoot -Force -Directory -ErrorAction Stop)) {
        if ($preservedRootDirectories.Contains($rootDirectory.Name)) { continue }
        Assert-NmapRegularNonReparseItem -Item $rootDirectory -ExpectedType Directory
        Move-Item -LiteralPath $rootDirectory.FullName -Destination $rootQuarantine -Force -ErrorAction Stop
        $movedEntryCount++
    }
    Assert-UnverifiedEvidenceQuarantineDirectory -Path $quarantineRoot

    $script:Manifest.parameters['unverifiedResumeEvidenceQuarantine'] = $quarantineRoot
    $script:Manifest.parameters['unverifiedResumeEvidenceEntries'] = $movedEntryCount
    Write-RunManifest
    Write-Log -Level WARN -Message ("A prior checksum baseline was unavailable. Quarantined {0} unverified derived evidence entr{1} outside the run at {2}; it cannot be parsed or added to the new checksum baseline." -f
        $movedEntryCount, $(if ($movedEntryCount -eq 1) { 'y' } else { 'ies' }), $quarantineRoot)
    $script:SuppressArtifactHashFinalization = $false
}

function ConvertTo-NmapPortSpecification {
    param([int[]]$Ports)
    $normalizedPorts = @($Ports | Where-Object { $_ -ge 1 -and $_ -le 65535 } | Sort-Object -Unique)
    if ($normalizedPorts.Count -eq 0) { return '' }
    $ranges = New-Object System.Collections.Generic.List[System.String]
    $rangeStart = [int]$normalizedPorts[0]
    $rangeEnd = $rangeStart
    for ($index = 1; $index -lt $normalizedPorts.Count; $index++) {
        $port = [int]$normalizedPorts[$index]
        if ($port -eq ($rangeEnd + 1)) {
            $rangeEnd = $port
            continue
        }
        [void]$ranges.Add($(if ($rangeStart -eq $rangeEnd) { [string]$rangeStart } else { '{0}-{1}' -f $rangeStart, $rangeEnd }))
        $rangeStart = $port
        $rangeEnd = $port
    }
    [void]$ranges.Add($(if ($rangeStart -eq $rangeEnd) { [string]$rangeStart } else { '{0}-{1}' -f $rangeStart, $rangeEnd }))
    return $ranges -join ','
}

function Invoke-NmapEnumeration {
    param([Parameter(Mandatory = $true)]$Scope)
    $stageErrorStart = $script:ErrorCount
    Set-StageStatus -Name 'nmap' -Status 'running'
    $udpBase = Join-Path $script:RawDirectory 'nmap-udp'
    $udpXml = $udpBase + '.xml'
    # A prior UDP result is never current for an invocation that did not
    # request UDP. Do this before every tool/data early return so Report cannot
    # ingest the old file merely because this invocation could not reach the
    # UDP phase.
    if (-not $EnableUdp) { Move-NmapOutputAside -BasePath $udpBase }
    $nmap = Find-Tool -Name 'nmap.exe'
    if (-not $nmap) {
        if ($EnableUdp) { Move-NmapOutputAside -BasePath $udpBase }
        Write-Log -Level ERROR -Message 'Nmap was not found. Run -Action Install or install it from nmap.org, then rerun Doctor.'
        Set-StageStatus -Name 'nmap' -Status 'failed' -Detail 'Nmap not found'
        return @()
    }
    $selectedNmapScripts = @(Get-SelectedNmapScripts)
    try {
        [void](Initialize-NmapDataBaseline -NmapPath $nmap -SelectedScripts $selectedNmapScripts)
    }
    catch {
        if ($EnableUdp) { Move-NmapOutputAside -BasePath $udpBase }
        Write-Log -Level ERROR -Message ("Nmap executable/data initialization failed: {0}" -f $_.Exception.Message)
        Set-StageStatus -Name 'nmap' -Status 'failed' -Detail 'Nmap data directory or frozen tree validation failed before scanning'
        return @()
    }

    $rawCapable = (Get-IsAdministrator) -and (Test-NpcapAvailable)
    $scanMode = if ($rawCapable) { '-sS' } else { '-sT' }
    $udpCheckpointReused = $false
    if ($EnableUdp) {
        if ($rawCapable) {
            $udpCheckpointReused = Test-Checkpoint -XmlPath $udpXml
            if (-not $udpCheckpointReused) { Move-NmapOutputAside -BasePath $udpBase }
        }
        else {
            Move-NmapOutputAside -BasePath $udpBase
        }
    }
    if (-not $rawCapable) {
        Write-Log -Level WARN -Message 'Administrator rights and Npcap were not both available; using TCP connect scans and skipping raw-only features.'
    }
    $common = @('-n', '-vv', '--reason', '--stats-every', '15s', '-T3', '--max-retries', '2', '--host-timeout', ("{0}m" -f $HostTimeoutMinutes), '--max-rate', [string]$MaxRate, '-iL', $Scope.TargetFile)

    $discoveryBase = Join-Path $script:RawDirectory 'nmap-discovery'
    $discoveryXml = $discoveryBase + '.xml'
    $discoveryReused = Test-Checkpoint -XmlPath $discoveryXml
    if ($discoveryReused) {
        Write-Log -Level INFO -Message ("Resume: keeping existing discovery output {0}." -f $discoveryXml)
    }
    else {
        Move-NmapOutputAside -BasePath $discoveryBase
        $discoveryArgs = @('-sn', '-n', '-vv', '--reason', '--stats-every', '15s', '-T3', '--max-retries', '2', '--host-timeout', ("{0}m" -f $HostTimeoutMinutes), '-iL', $Scope.TargetFile, '-oA', $discoveryBase)
        if ($rawCapable) {
            $discoveryArgs = @('-sn', '-PE', '-PS22,80,135,139,443,445,3389,5985', '-PA80,443,445') + $discoveryArgs[1..($discoveryArgs.Count - 1)]
        }
        Invoke-NmapProcess -FilePath $nmap -ArgumentList $discoveryArgs -Name 'nmap-discovery' -TimeoutSeconds $CommandTimeoutSeconds -ContinueOnError -ValidateFrozenDataTree | Out-Null
        if ($script:NmapDataIntegrityFailed) {
            Set-StageStatus -Name 'nmap' -Status 'failed' -Detail 'Frozen Nmap executable/data tree drifted during discovery'
            return @()
        }
    }
    $discoveryValid = Test-NmapXmlSuccess -Path $discoveryXml
    if (-not $discoveryValid) {
        Write-Log -Level ERROR -Message 'Nmap discovery did not produce complete successful XML; discovery evidence is partial and will not be reused.'
    }

    $tcpBase = Join-Path $script:RawDirectory 'nmap-tcp'
    $tcpXml = $tcpBase + '.xml'
    $tcpReused = Test-Checkpoint -XmlPath $tcpXml
    if ($tcpReused) {
        Write-Log -Level INFO -Message ("Resume: keeping existing TCP output {0}." -f $tcpXml)
    }
    else {
        Move-NmapOutputAside -BasePath $tcpBase
        $portArguments = switch ($ScanProfile) {
            'Quick' { @('-F') }
            'Deep' { @('-p-') }
            default { @('--top-ports', '1000') }
        }
        $tcpArgs = @($scanMode, '-Pn', '--open') + $portArguments + $common + @('-oA', $tcpBase)
        $tcpResult = Invoke-NmapProcess -FilePath $nmap -ArgumentList $tcpArgs -Name 'nmap-tcp' -TimeoutSeconds $CommandTimeoutSeconds -ContinueOnError -ValidateFrozenDataTree
        if ($script:NmapDataIntegrityFailed) {
            Set-StageStatus -Name 'nmap' -Status 'failed' -Detail 'Frozen Nmap executable/data tree drifted during TCP enumeration'
            return @()
        }
        if (-not $tcpResult.Success -and $rawCapable) {
            Write-Log -Level WARN -Message 'The SYN scan failed; retrying the same scope with a TCP connect scan.'
            $tcpArgs[0] = '-sT'
            Invoke-NmapProcess -FilePath $nmap -ArgumentList $tcpArgs -Name 'nmap-tcp-connect-fallback' -TimeoutSeconds $CommandTimeoutSeconds -ContinueOnError -ValidateFrozenDataTree | Out-Null
            if ($script:NmapDataIntegrityFailed) {
                Set-StageStatus -Name 'nmap' -Status 'failed' -Detail 'Frozen Nmap executable/data tree drifted during TCP fallback'
                return @()
            }
        }
    }

    $tcpValid = Test-NmapXmlSuccess -Path $tcpXml
    if (-not $tcpValid) {
        Write-Log -Level ERROR -Message 'Nmap TCP enumeration did not produce complete successful XML; service enrichment and web follow-ups will not trust this phase.'
    }
    $serviceBaseForDependency = Join-Path $script:RawDirectory 'nmap-services'
    if ($Resume -and -not $tcpReused -and
        (Test-Path -LiteralPath ($serviceBaseForDependency + '.xml') -PathType Leaf)) {
        Write-Log -Level WARN -Message 'The TCP baseline was rerun, so prior service enrichment is stale and cannot be reused.'
        Move-NmapOutputAside -BasePath $serviceBaseForDependency
    }
    $tcpInventory = @()
    if ($tcpValid) { $tcpInventory = @(Read-NmapXml -Path $tcpXml -AllowedAddresses $Scope.Targets) }
    $tcpInventory | Export-Csv -LiteralPath (Join-Path $script:NormalizedDirectory 'tcp-services.csv') -NoTypeInformation -Encoding UTF8
    $serviceInventory = $tcpInventory
    if ($tcpInventory.Count -gt 0) {
        $openHosts = @($tcpInventory | Select-Object -ExpandProperty Address -Unique | Sort-Object)
        $openPorts = ConvertTo-NmapPortSpecification -Ports @($tcpInventory | Select-Object -ExpandProperty Port)
        if ($openPorts.Length -gt 12000) {
            Write-Log -Level WARN -Message ("The sparse service port specification remained {0} characters after range compression; using 1-65535 to stay below the Windows command-line limit." -f $openPorts.Length)
            $openPorts = '1-65535'
        }
        $openHostPath = Join-Path $script:ScopeDirectory 'hosts-with-open-tcp.txt'
        Write-Utf8File -Path $openHostPath -Content (($openHosts -join [Environment]::NewLine) + [Environment]::NewLine)
        $serviceBase = Join-Path $script:RawDirectory 'nmap-services'
        $serviceXml = $serviceBase + '.xml'
        $serviceReused = $tcpReused -and (Test-Checkpoint -XmlPath $serviceXml)
        if ($serviceReused) {
            Write-Log -Level INFO -Message ("Resume: keeping existing service output {0}." -f $serviceXml)
        }
        else {
            Move-NmapOutputAside -BasePath $serviceBase
            $versionIntensity = if ($ScanProfile -eq 'Deep') { '--version-all' } else { '--version-light' }
            $scriptTimeout = if ($ScanProfile -eq 'Deep') { '10m' } else { '3m' }
            $serviceArgs = @($scanMode, '-Pn', '-n', '-vv', '--reason', '--stats-every', '15s', '-T3', '--max-retries', '2', '--host-timeout', ("{0}m" -f $HostTimeoutMinutes), '--script-timeout', $scriptTimeout, '--max-rate', [string]$MaxRate, '-sV', $versionIntensity, '-p', $openPorts, '--script', ($script:NmapDataBaseline.SelectedScriptPaths -join ','), '-iL', $openHostPath)
            if ($rawCapable -and $ScanProfile -eq 'Deep') { $serviceArgs += @('-O', '--osscan-limit') }
            $serviceArgs += @('-oA', $serviceBase)
            $serviceResult = Invoke-NmapProcess -FilePath $nmap -ArgumentList $serviceArgs -Name 'nmap-services' -TimeoutSeconds $CommandTimeoutSeconds -ContinueOnError -ValidateFrozenDataTree
            if ($script:NmapDataIntegrityFailed) {
                Set-StageStatus -Name 'nmap' -Status 'failed' -Detail 'Frozen Nmap executable/data tree drifted during service enumeration'
                return @()
            }
            if (-not $serviceResult.Success -and $rawCapable) {
                Write-Log -Level WARN -Message 'The raw service scan failed; retrying with a TCP connect scan and without OS detection.'
                $serviceArgs[0] = '-sT'
                $serviceArgs = @($serviceArgs | Where-Object { $_ -ne '-O' -and $_ -ne '--osscan-limit' })
                Invoke-NmapProcess -FilePath $nmap -ArgumentList $serviceArgs -Name 'nmap-services-connect-fallback' -TimeoutSeconds $CommandTimeoutSeconds -ContinueOnError -ValidateFrozenDataTree | Out-Null
                if ($script:NmapDataIntegrityFailed) {
                    Set-StageStatus -Name 'nmap' -Status 'failed' -Detail 'Frozen Nmap executable/data tree drifted during service fallback'
                    return @()
                }
            }
        }
        $serviceValid = Test-NmapXmlSuccess -Path $serviceXml
        if ($serviceValid) {
            $enrichedInventory = @(Read-NmapXml -Path $serviceXml -AllowedAddresses $Scope.Targets)
            $serviceInventory = @(Merge-NmapInventory -Baseline $tcpInventory -Enrichment $enrichedInventory)
            if ($enrichedInventory.Count -lt $tcpInventory.Count) {
                Write-Log -Level INFO -Message ("Service enrichment returned {0} record(s); retained all {1} TCP baseline record(s) and overlaid matching enrichment." -f $enrichedInventory.Count, $tcpInventory.Count)
            }
        }
        else {
            Write-Log -Level ERROR -Message 'Nmap service enrichment did not produce complete successful XML; the validated TCP baseline was retained without stale enrichment.'
        }
    }
    else {
        Write-Log -Level WARN -Message 'The TCP scan returned no open ports; service enrichment was skipped.'
    }

    $trustedUdpXml = $null
    if ($EnableUdp) {
        if (-not $rawCapable) {
            Move-NmapOutputAside -BasePath $udpBase
            Write-Log -Level WARN -Message 'UDP enumeration requires Administrator rights and Npcap; the UDP phase was skipped.'
        }
        else {
            if ($udpCheckpointReused) {
                Write-Log -Level INFO -Message ("Resume: keeping existing UDP output {0}." -f $udpXml)
                $trustedUdpXml = $udpXml
            }
            else {
                Move-NmapOutputAside -BasePath $udpBase
                $udpCount = switch ($ScanProfile) { 'Quick' { 20 } 'Deep' { 100 } default { 50 } }
                $udpArgs = @('-sU', '-Pn', '-n', '-vv', '--reason', '--open', '--top-ports', [string]$udpCount, '-sV', '--version-light', '--stats-every', '15s', '-T3', '--max-retries', '2', '--host-timeout', ("{0}m" -f $HostTimeoutMinutes), '--max-rate', [string]$MaxRate, '-iL', $Scope.TargetFile, '-oA', $udpBase)
                $udpResult = Invoke-NmapProcess -FilePath $nmap -ArgumentList $udpArgs -Name 'nmap-udp' -TimeoutSeconds $CommandTimeoutSeconds -ContinueOnError -ValidateFrozenDataTree
                if ($script:NmapDataIntegrityFailed) {
                    Set-StageStatus -Name 'nmap' -Status 'failed' -Detail 'Frozen Nmap executable/data tree drifted during UDP enumeration'
                    return @()
                }
                $udpXmlValid = Test-NmapXmlSuccess -Path $udpXml
                if ($udpResult.Success -and $udpXmlValid) {
                    $trustedUdpXml = $udpXml
                }
                else {
                    Write-Log -Level ERROR -Message 'Nmap UDP enumeration did not produce trusted, complete successful XML; UDP results were excluded.'
                    Move-NmapOutputAside -BasePath $udpBase
                }
            }
        }
    }
    else {
        Move-NmapOutputAside -BasePath $udpBase
    }

    $allInventory = New-Object System.Collections.Generic.List[System.Object]
    foreach ($record in $serviceInventory) { [void]$allInventory.Add($record) }
    if ($trustedUdpXml) {
        foreach ($record in @(Read-NmapXml -Path $trustedUdpXml -AllowedAddresses $Scope.Targets)) { [void]$allInventory.Add($record) }
    }
    $allInventory.ToArray() | Export-Csv -LiteralPath (Join-Path $script:NormalizedDirectory 'services.csv') -NoTypeInformation -Encoding UTF8
    $nmapStatus = if (-not $tcpValid) { 'failed' } elseif ($script:ErrorCount -gt $stageErrorStart) { 'partial' } else { 'complete' }
    Set-StageStatus -Name 'nmap' -Status $nmapStatus -Detail ("{0} open service record(s); discovery XML valid={1}; TCP XML valid={2}" -f $allInventory.Count, $discoveryValid, $tcpValid)
    return $allInventory.ToArray()
}

function Test-UriWithinAllowedAddresses {
    param(
        [AllowEmptyString()][string]$Value,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$AllowedSet
    )
    if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
    $candidate = $Value.Trim()
    $parsedAddress = $null
    if ([Net.IPAddress]::TryParse($candidate, [ref]$parsedAddress)) {
        return $parsedAddress.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork -and $AllowedSet.Contains($parsedAddress.ToString())
    }
    $parsedUri = $null
    if (-not [Uri]::TryCreate($candidate, [UriKind]::Absolute, [ref]$parsedUri)) { return $false }
    if (-not [Net.IPAddress]::TryParse($parsedUri.Host, [ref]$parsedAddress)) { return $false }
    return $parsedAddress.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork -and $AllowedSet.Contains($parsedAddress.ToString())
}

function Get-JsonRecordNetworkLocation {
    param($Record)
    if ($null -eq $Record) { return '' }
    foreach ($propertyName in @('cptc_connection_url', 'url', 'input', 'matched-at', 'matched', 'host')) {
        $property = $Record.PSObject.Properties[$propertyName]
        if ($property -and -not [string]::IsNullOrWhiteSpace([string]$property.Value)) {
            return [string]$property.Value
        }
    }
    return ''
}

function Select-JsonRecordsWithinScope {
    param(
        [object[]]$Records,
        [string[]]$AllowedAddresses,
        [Parameter(Mandatory = $true)][string]$SourceName
    )
    $allowedSet = New-AllowedAddressSet -Addresses $AllowedAddresses
    $accepted = New-Object System.Collections.Generic.List[System.Object]
    $rejected = 0
    foreach ($record in @($Records)) {
        $location = Get-JsonRecordNetworkLocation -Record $record
        if (Test-UriWithinAllowedAddresses -Value $location -AllowedSet $allowedSet) {
            [void]$accepted.Add($record)
        }
        else {
            $rejected++
        }
    }
    if ($rejected -gt 0) {
        Write-Log -Level WARN -Message ("Discarded {0} record(s) from {1} because their endpoint was missing, not an IPv4 literal, or outside frozen scope." -f $rejected, $SourceName)
    }
    return $accepted.ToArray()
}

function Get-FrozenHostnameMappings {
    param(
        [Parameter(Mandatory = $true)]$Scope
    )
    $mappings = New-Object System.Collections.Generic.List[System.Object]
    $seen = New-Object -TypeName 'System.Collections.Generic.HashSet[System.String]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
    $allowedSet = New-AllowedAddressSet -Addresses $Scope.Targets
    if (-not $Scope.ResolutionMap -or -not (Test-Path -LiteralPath $Scope.ResolutionMap -PathType Leaf)) {
        return $mappings.ToArray()
    }
    try {
        $resolutionJson = if ($Resume -and $script:OriginalResolutionMapJson) {
            $script:OriginalResolutionMapJson
        }
        else {
            Read-Utf8File -Path $Scope.ResolutionMap
        }
        $resolutionRecords = @($resolutionJson | ConvertFrom-Json)
    }
    catch {
        Write-Log -Level WARN -Message ("Could not read frozen hostname mappings from {0}: {1}" -f $Scope.ResolutionMap, $_.Exception.Message)
        return $mappings.ToArray()
    }
    $hostPattern = '^(?=.{1,253}$)[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)*$'
    foreach ($resolutionRecord in $resolutionRecords) {
        $inputProperty = $resolutionRecord.PSObject.Properties['input']
        $resolvedProperty = $resolutionRecord.PSObject.Properties['resolved']
        $kindProperty = $resolutionRecord.PSObject.Properties['kind']
        if (-not $inputProperty -or -not $resolvedProperty -or -not $kindProperty -or [string]$kindProperty.Value -ine 'hostname') { continue }
        $hostName = ([string]$inputProperty.Value).Trim().TrimEnd('.').ToLowerInvariant()
        $parsedAddress = $null
        if ($hostName -notmatch $hostPattern -or
            -not [Net.IPAddress]::TryParse([string]$resolvedProperty.Value, [ref]$parsedAddress) -or
            $parsedAddress.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork) {
            continue
        }
        $address = $parsedAddress.ToString()
        if (-not $allowedSet.Contains($address)) {
            Write-Log -Level WARN -Message ("Ignored frozen hostname mapping outside scope: {0} -> {1}" -f $hostName, $address)
            continue
        }
        $key = '{0}|{1}' -f $hostName, $address
        if ($seen.Add($key)) {
            [void]$mappings.Add([pscustomobject]@{ HostName = $hostName; Address = $address })
        }
    }
    return $mappings.ToArray()
}

function Get-WebProbePlan {
    param(
        [object[]]$Inventory,
        [Parameter(Mandatory = $true)]$Scope
    )
    $probes = New-Object System.Collections.Generic.List[System.Object]
    $seen = New-Object -TypeName 'System.Collections.Generic.HashSet[System.String]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
    $allowedSet = New-AllowedAddressSet -Addresses $Scope.Targets
    $hostnameMap = @{}
    foreach ($mapping in @(Get-FrozenHostnameMappings -Scope $Scope)) {
        if (-not $hostnameMap.ContainsKey($mapping.Address)) {
            $hostnameMap[$mapping.Address] = New-Object System.Collections.Generic.List[System.String]
        }
        if (-not $hostnameMap[$mapping.Address].Contains($mapping.HostName)) { [void]$hostnameMap[$mapping.Address].Add($mapping.HostName) }
    }
    $httpPorts = @(80, 81, 3000, 5000, 7001, 8000, 8008, 8080, 8081, 8888, 9000)
    $httpsPorts = @(443, 4443, 7443, 8443, 9443, 10443)
    foreach ($record in @($Inventory)) {
        if ($record.Protocol -ne 'tcp') { continue }
        $parsedAddress = $null
        if (-not [Net.IPAddress]::TryParse([string]$record.Address, [ref]$parsedAddress) -or
            $parsedAddress.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork -or
            -not $allowedSet.Contains($parsedAddress.ToString())) {
            Write-Log -Level WARN -Message ("Skipped out-of-scope web follow-up address from parsed inventory: {0}" -f $record.Address)
            continue
        }
        $serviceText = ('{0} {1}' -f $record.Service, $record.Tunnel).ToLowerInvariant()
        $scheme = $null
        if ($httpsPorts -contains [int]$record.Port -or $serviceText -match 'https|ssl') { $scheme = 'https' }
        elseif ($httpPorts -contains [int]$record.Port -or $serviceText -match 'http') { $scheme = 'http' }
        if ($scheme) {
            $address = $parsedAddress.ToString()
            $port = [int]$record.Port
            $defaultPort = ($scheme -eq 'http' -and $port -eq 80) -or ($scheme -eq 'https' -and $port -eq 443)
            $connectionUrl = if ($defaultPort) { '{0}://{1}/' -f $scheme, $address } else { '{0}://{1}:{2}/' -f $scheme, $address, $port }
            $baseKey = '{0}|{1}|' -f $connectionUrl, $port
            if ($seen.Add($baseKey)) {
                [void]$probes.Add([pscustomobject]@{
                    ConnectionUrl = $connectionUrl
                    DisplayUrl = $connectionUrl
                    Address = $address
                    Port = $port
                    Scheme = $scheme
                    HostName = ''
                    HostHeader = ''
                    SniName = ''
                    Source = 'address'
                })
            }
            if ($hostnameMap.ContainsKey($address)) {
                foreach ($hostName in $hostnameMap[$address]) {
                    $displayUrl = if ($defaultPort) { '{0}://{1}/' -f $scheme, $hostName } else { '{0}://{1}:{2}/' -f $scheme, $hostName, $port }
                    $hostHeader = if ($defaultPort) { $hostName } else { '{0}:{1}' -f $hostName, $port }
                    $key = '{0}|{1}|{2}' -f $connectionUrl, $hostHeader, $hostName
                    if ($seen.Add($key)) {
                        [void]$probes.Add([pscustomobject]@{
                            ConnectionUrl = $connectionUrl
                            DisplayUrl = $displayUrl
                            Address = $address
                            Port = $port
                            Scheme = $scheme
                            HostName = $hostName
                            HostHeader = $hostHeader
                            SniName = $hostName
                            Source = 'frozen-hostname'
                        })
                    }
                }
            }
        }
    }
    return @($probes.ToArray() | Sort-Object Address, Port, HostName)
}

function Add-WebProbeJsonLines {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$DestinationPath,
        [object[]]$Probes
    )
    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
        return [pscustomobject]@{ Exists = $false; NonBlankLines = 0; ValidRecords = 0; MalformedRecords = 0; Valid = $false }
    }
    $probeMap = @{}
    foreach ($probe in @($Probes)) { $probeMap[$probe.ConnectionUrl.ToLowerInvariant().TrimEnd('/')] = $probe }
    $nonBlankLines = 0
    $validRecords = 0
    $malformedRecords = 0
    try {
        foreach ($line in Read-Utf8Lines -Path $SourcePath) {
            if (-not $line.Trim()) { continue }
            $nonBlankLines++
            try {
                $record = $line | ConvertFrom-Json
                $location = Get-JsonRecordNetworkLocation -Record $record
                $probeKey = ([string]$location).ToLowerInvariant().TrimEnd('/')
                $probe = if ($probeMap.ContainsKey($probeKey)) { $probeMap[$probeKey] } elseif (@($Probes).Count -eq 1) { @($Probes)[0] } else { $null }
                if (-not $probe) {
                    $locationUri = $null
                    if ([Uri]::TryCreate([string]$location, [UriKind]::Absolute, [ref]$locationUri)) {
                        $matchingProbes = @($Probes | Where-Object {
                            $_.Address -eq $locationUri.Host -and $_.Port -eq $locationUri.Port -and $_.Scheme -eq $locationUri.Scheme
                        })
                        if ($matchingProbes.Count -eq 1) { $probe = $matchingProbes[0] }
                    }
                }
                if ($probe) {
                    $record | Add-Member -NotePropertyName cptc_connection_url -NotePropertyValue $probe.ConnectionUrl -Force
                    $record | Add-Member -NotePropertyName cptc_display_url -NotePropertyValue $probe.DisplayUrl -Force
                    $record | Add-Member -NotePropertyName cptc_hostname -NotePropertyValue $probe.HostName -Force
                    $record | Add-Member -NotePropertyName cptc_connection_ip -NotePropertyValue $probe.Address -Force
                }
                Add-Utf8Line -Path $DestinationPath -Content ($record | ConvertTo-Json -Depth 12 -Compress)
                $validRecords++
            }
            catch {
                $malformedRecords++
                Write-Log -Level ERROR -Message ("Malformed nonblank JSONL record in {0} at record {1}: {2}" -f $SourcePath, $nonBlankLines, $_.Exception.Message)
            }
        }
    }
    catch {
        $malformedRecords++
        Write-Log -Level ERROR -Message ("Could not decode/read JSONL output {0} as UTF-8: {1}" -f $SourcePath, $_.Exception.Message)
    }
    return [pscustomobject]@{
        Exists = $true
        NonBlankLines = $nonBlankLines
        ValidRecords = $validRecords
        MalformedRecords = $malformedRecords
        Valid = ($malformedRecords -eq 0)
    }
}

function Invoke-NativeWebProbe {
    param([object[]]$Probes)
    $outputPath = Join-Path $script:RawDirectory 'native-web.jsonl'
    Write-Utf8File -Path $outputPath -Content ''
    $curl = Find-Tool -Name 'curl.exe'
    $nullDevice = if ($env:OS -eq 'Windows_NT') { 'NUL' } else { '/dev/null' }
    foreach ($probe in @($Probes)) {
        $record = [ordered]@{
            url = $probe.DisplayUrl
            cptc_connection_url = $probe.ConnectionUrl
            cptc_display_url = $probe.DisplayUrl
            cptc_hostname = $probe.HostName
            cptc_connection_ip = $probe.Address
            timestampUtc = [DateTime]::UtcNow.ToString('o')
            status_code = $null
            server = $null
            content_type = $null
            location = $null
            error = $null
        }
        $requiresCurl = ($probe.Scheme -eq 'https') -or -not [string]::IsNullOrWhiteSpace([string]$probe.HostName)
        if ($requiresCurl) {
            if (-not $curl) {
                $record.error = if ($probe.Scheme -eq 'https') {
                    'curl.exe is unavailable; the HTTPS probe was skipped because native HttpWebRequest certificate validation commonly rejects self-signed or IP-mismatched CPTC services.'
                }
                else {
                    'curl.exe is unavailable; the hostname-aware probe was skipped because native HttpWebRequest cannot guarantee frozen-IP Host/SNI behavior.'
                }
                Write-Log -Level ERROR -Message ("{0} URL={1}" -f $record.error, $probe.DisplayUrl)
                Add-Utf8Line -Path $outputPath -Content ($record | ConvertTo-Json -Compress)
                continue
            }
            # -q must be the first curl argument so per-user .curlrc/_curlrc
            # files cannot add redirects, proxies, credentials, or targets.
            $curlArgs = @('-q', '--head', '--silent', '--show-error', '--insecure', '--max-time', '15', '--connect-timeout', '10', '--noproxy', '*')
            if ($probe.HostName) {
                $resolveValue = '{0}:{1}:{2}' -f $probe.HostName, $probe.Port, $probe.Address
                $curlArgs += @('--resolve', $resolveValue)
            }
            $curlArgs += @('--output', $nullDevice, '--dump-header', '-', $probe.DisplayUrl)
            $curlLabel = if ($probe.HostName) { $probe.HostName } else { $probe.Address }
            $curlResult = Invoke-LoggedProcess -FilePath $curl -ArgumentList $curlArgs -Name ("curl-web-{0}-{1}" -f $curlLabel, $probe.Port) -TimeoutSeconds 30 -ContinueOnError -ClearEnvironmentVariables @('HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY', 'http_proxy', 'https_proxy', 'all_proxy')
            if ($curlResult.Success) {
                $statusMatches = @([regex]::Matches($curlResult.Stdout, '(?im)^HTTP/\S+\s+(\d{3})'))
                if ($statusMatches.Count -gt 0) { $record.status_code = [int]$statusMatches[$statusMatches.Count - 1].Groups[1].Value }
                foreach ($headerName in @('Server', 'Content-Type', 'Location')) {
                    $headerMatch = [regex]::Match($curlResult.Stdout, ('(?im)^{0}:\s*(.+?)\s*$' -f [regex]::Escape($headerName)))
                    if ($headerMatch.Success) {
                        switch ($headerName) {
                            'Server' { $record.server = $headerMatch.Groups[1].Value }
                            'Content-Type' { $record.content_type = $headerMatch.Groups[1].Value }
                            'Location' { $record.location = $headerMatch.Groups[1].Value }
                        }
                    }
                }
            }
            else {
                $record.error = $curlResult.Stderr.Trim()
                if (-not $record.error) { $record.error = "curl.exe failed with exit code $($curlResult.ExitCode)." }
            }
            Add-Utf8Line -Path $outputPath -Content ($record | ConvertTo-Json -Compress)
            continue
        }

        $response = $null
        try {
            $request = [Net.HttpWebRequest]::Create($probe.ConnectionUrl)
            $request.Method = 'HEAD'
            $request.AllowAutoRedirect = $false
            $request.Proxy = $null
            $request.Timeout = 10000
            $request.ReadWriteTimeout = 10000
            $request.UserAgent = 'CPTC-Authorized-Enumerator/1.0'
            try {
                $response = [Net.HttpWebResponse]$request.GetResponse()
            }
            catch [Net.WebException] {
                if ($_.Exception.Response) { $response = [Net.HttpWebResponse]$_.Exception.Response } else { throw }
            }
            try {
                $record.status_code = [int]$response.StatusCode
                $record.server = [string]$response.Server
                $record.content_type = [string]$response.ContentType
                $record.location = [string]$response.Headers['Location']
            }
            finally { if ($response) { $response.Close() } }
        }
        catch {
            $record.error = $_.Exception.Message
        }
        Add-Utf8Line -Path $outputPath -Content ($record | ConvertTo-Json -Compress)
    }
    return $outputPath
}

function Move-PriorWebEvidenceAside {
    $priorFiles = New-Object System.Collections.Generic.List[System.IO.FileInfo]
    foreach ($pattern in @('httpx.jsonl', 'httpx-*.jsonl', 'nuclei.jsonl', 'nuclei-*.jsonl', 'native-web.jsonl', 'ffuf_*.json')) {
        foreach ($file in @(Get-ChildItem -LiteralPath $script:RawDirectory -Filter $pattern -File -ErrorAction SilentlyContinue)) {
            if (-not $priorFiles.Contains($file)) { [void]$priorFiles.Add($file) }
        }
    }
    if ($priorFiles.Count -eq 0) { return }
    $archiveDirectory = Join-Path (Join-Path $script:RawDirectory 'web-history') ('{0}_{1}' -f [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'), ([Guid]::NewGuid().ToString('N').Substring(0, 8)))
    [void](New-Item -ItemType Directory -Path $archiveDirectory -Force)
    foreach ($file in $priorFiles) {
        Move-Item -LiteralPath $file.FullName -Destination (Join-Path $archiveDirectory $file.Name) -Force
    }
    Write-Log -Level INFO -Message ("Archived {0} prior web evidence file(s) under {1} before generating current group outputs." -f $priorFiles.Count, $archiveDirectory)
}

function Move-FailedWebOutputAside {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }
    $failedPath = '{0}.partial_{1}_{2}' -f $Path, [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'), ([Guid]::NewGuid().ToString('N').Substring(0, 8))
    Move-Item -LiteralPath $Path -Destination $failedPath -Force
    Write-Log -Level WARN -Message ("Preserved untrusted partial web output as {0}; it will not be merged into current results." -f $failedPath)
}

function New-FrozenFfufWordlist {
    param([Parameter(Mandatory = $true)][string]$SourcePath)
    $sourceFullPath = [IO.Path]::GetFullPath($SourcePath)
    if (-not (Test-Path -LiteralPath $sourceFullPath -PathType Leaf)) { throw "Wordlist not found: $sourceFullPath" }
    $maximumWordlistBytes = 134217728
    $sourceStream = $null
    $destinationStream = $null
    $sha256 = $null
    $temporaryPath = Join-Path $script:ScopeDirectory ('.ffuf-wordlist-{0}.tmp' -f [Guid]::NewGuid().ToString('N'))
    $frozenPath = Join-Path $script:ScopeDirectory 'ffuf-wordlist.txt'
    try {
        # FileShare.Read prevents a cooperating Windows process from replacing,
        # truncating, or writing the source while its exact bytes are frozen.
        $sourceStream = [IO.File]::Open($sourceFullPath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
        $sourceLength = [int64]$sourceStream.Length
        if ($sourceLength -lt 1) { throw 'The ffuf wordlist is empty.' }
        if ($sourceLength -gt $maximumWordlistBytes) {
            throw ("The ffuf wordlist is {0} bytes; the safety cap is {1} bytes." -f $sourceLength, $maximumWordlistBytes)
        }
        $sha256 = [Security.Cryptography.SHA256]::Create()
        $sourceHash = ([BitConverter]::ToString($sha256.ComputeHash($sourceStream))).Replace('-', '')
        $sourceStream.Position = 0
        $destinationStream = [IO.File]::Open($temporaryPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $sourceStream.CopyTo($destinationStream)
        $destinationStream.Flush()
        $destinationStream.Dispose()
        $destinationStream = $null
        $sourceStream.Dispose()
        $sourceStream = $null
        if ((Get-Item -LiteralPath $temporaryPath -Force).Length -ne $sourceLength) {
            throw 'The frozen ffuf wordlist length does not match its source.'
        }
        $frozenHash = (Get-FileHash -LiteralPath $temporaryPath -Algorithm SHA256).Hash.ToUpperInvariant()
        if ($frozenHash -ne $sourceHash) { throw 'The frozen ffuf wordlist SHA-256 does not match its locked source.' }
        if (Test-Path -LiteralPath $frozenPath -PathType Leaf) { Remove-Item -LiteralPath $frozenPath -Force }
        Move-Item -LiteralPath $temporaryPath -Destination $frozenPath -ErrorAction Stop
        $script:Manifest.tools['ffufWordlist'] = [ordered]@{
            sourcePath = $sourceFullPath
            frozenPath = $frozenPath
            sizeBytes = $sourceLength
            sha256 = $sourceHash
            frozenUtc = [DateTime]::UtcNow.ToString('o')
            maximumBytes = $maximumWordlistBytes
        }
        Write-RunManifest
        Write-Log -Level INFO -Message ("Froze ffuf wordlist to {0}: {1} bytes, SHA-256 {2}." -f $frozenPath, $sourceLength, $sourceHash)
        return $frozenPath
    }
    finally {
        if ($destinationStream) { try { $destinationStream.Dispose() } catch { } }
        if ($sourceStream) { try { $sourceStream.Dispose() } catch { } }
        if ($sha256) { try { $sha256.Dispose() } catch { } }
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) { Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue }
    }
}

function Assert-FfufJsonOutput {
    param([Parameter(Mandatory = $true)][string]$Path)
    $content = Read-Utf8File -Path $Path
    if ([string]::IsNullOrWhiteSpace($content)) { throw 'the output is empty' }
    $document = ConvertFrom-Json -InputObject $content
    if ($null -eq $document -or $document -is [System.Array]) {
        throw 'the top-level JSON value is not an object'
    }
    $resultsProperty = $document.PSObject.Properties['results']
    if (-not $resultsProperty) { throw "the top-level object has no 'results' property" }
    if ($null -eq $resultsProperty.Value -or -not ($resultsProperty.Value -is [System.Array])) {
        throw "the top-level 'results' property is not an array"
    }
    return $true
}

function Test-FrozenFfufWordlistIntegrity {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ExpectedSha256,
        [Parameter(Mandatory = $true)][int64]$ExpectedSize,
        [Parameter(Mandatory = $true)][string]$Moment
    )
    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'the frozen file is missing' }
        $file = Get-Item -LiteralPath $Path -Force
        if ([int64]$file.Length -ne $ExpectedSize) {
            throw ("size changed from {0} to {1} bytes" -f $ExpectedSize, $file.Length)
        }
        $actualHash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
        if ($actualHash -ne $ExpectedSha256.ToUpperInvariant()) {
            throw ("SHA-256 changed from {0} to {1}" -f $ExpectedSha256, $actualHash)
        }
        return $true
    }
    catch {
        Write-Log -Level ERROR -Message ("Frozen ffuf wordlist integrity failed {0}: {1}. No further ffuf probes will run." -f $Moment, $_.Exception.Message)
        return $false
    }
}

function Invoke-WebEnumeration {
    param(
        [object[]]$Inventory,
        [Parameter(Mandatory = $true)]$Scope
    )
    $stageErrorStart = $script:ErrorCount
    Set-StageStatus -Name 'web' -Status 'running'
    Move-PriorWebEvidenceAside
    $httpxOutput = Join-Path $script:RawDirectory 'httpx.jsonl'
    $nativeWebOutput = Join-Path $script:RawDirectory 'native-web.jsonl'
    Write-Utf8File -Path $httpxOutput -Content ''
    Write-Utf8File -Path $nativeWebOutput -Content ''
    $probes = @(Get-WebProbePlan -Inventory $Inventory -Scope $Scope)
    if ($probes.Count -eq 0) {
        Write-Log -Level INFO -Message 'No HTTP(S) services were identified; web enumeration was skipped.'
        Set-StageStatus -Name 'web' -Status 'skipped' -Detail 'No web services identified'
        return
    }
    $urlPath = Join-Path $script:ScopeDirectory 'web-urls.txt'
    $connectionUrls = @($probes | Select-Object -ExpandProperty ConnectionUrl -Unique | Sort-Object)
    Write-Utf8File -Path $urlPath -Content (($connectionUrls -join [Environment]::NewLine) + [Environment]::NewLine)
    Write-Utf8File -Path (Join-Path $script:ScopeDirectory 'web-probes.json') -Content (ConvertTo-Json -InputObject $probes -Depth 6)
    $httpxConfigPath = Join-Path $script:ScopeDirectory 'httpx-config.yaml'
    $nucleiConfigPath = Join-Path $script:ScopeDirectory 'nuclei-config.yaml'
    $ffufConfigPath = Join-Path $script:ScopeDirectory 'ffuf-config.toml'
    Write-Utf8File -Path $httpxConfigPath -Content "{}$([Environment]::NewLine)"
    Write-Utf8File -Path $nucleiConfigPath -Content "{}$([Environment]::NewLine)"
    Write-Utf8File -Path $ffufConfigPath -Content "# Run-owned empty configuration; command-line safety controls follow.$([Environment]::NewLine)"
    $proxyEnvironmentNames = @('HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY', 'http_proxy', 'https_proxy', 'all_proxy')
    $hostnameProbeCount = @($probes | Where-Object { $_.HostName }).Count
    Write-Log -Level INFO -Message ("Generated {0} scope-bound web probe(s) across {1} frozen IP URL(s), including {2} frozen Host/SNI mapping(s). Redirect following is disabled." -f $probes.Count, $connectionUrls.Count, $hostnameProbeCount)

    $probeGroups = New-Object System.Collections.Generic.List[System.Object]
    $defaultProbes = @($probes | Where-Object { -not $_.HostName })
    if ($defaultProbes.Count -gt 0) {
        [void]$probeGroups.Add([pscustomobject]@{ Name = 'address-default'; HostName = ''; HostHeader = ''; Probes = $defaultProbes })
    }
    foreach ($hostnameGroup in @($probes | Where-Object { $_.HostName } | Group-Object -Property { '{0}|{1}' -f $_.HostName, $_.HostHeader })) {
        $firstProbe = @($hostnameGroup.Group)[0]
        [void]$probeGroups.Add([pscustomobject]@{ Name = $hostnameGroup.Name; HostName = $firstProbe.HostName; HostHeader = $firstProbe.HostHeader; Probes = @($hostnameGroup.Group) })
    }

    $httpx = Find-Tool -Name 'httpx.exe'
    if ($httpx) {
        $script:Manifest.parameters['webBackend'] = 'httpx'
        Write-RunManifest
        $groupCounter = 0
        foreach ($probeGroup in $probeGroups) {
            $groupCounter++
            $groupInput = Join-Path $script:ScopeDirectory ('httpx-input-{0:D3}.txt' -f $groupCounter)
            $groupOutput = Join-Path $script:RawDirectory ('httpx-{0:D3}.jsonl' -f $groupCounter)
            $groupUrls = @($probeGroup.Probes | Select-Object -ExpandProperty ConnectionUrl -Unique | Sort-Object)
            Write-Utf8File -Path $groupInput -Content (($groupUrls -join [Environment]::NewLine) + [Environment]::NewLine)
            $httpxArgs = @('-config', $httpxConfigPath, '-no-stdin', '-l', $groupInput, '-json', '-o', $groupOutput, '-status-code', '-content-length', '-content-type', '-title', '-web-server', '-tech-detect', '-ip', '-tls-grab', '-response-time', '-location', '-favicon', '-hash', 'sha256', '-threads', [string]$Throttle, '-rate-limit', [string]$WebRateLimit, '-timeout', '10', '-retries', '1', '-no-color', '-no-fallback', '-disable-update-check')
            if ($probeGroup.HostName) {
                $httpxArgs += @('-H', ('Host: {0}' -f $probeGroup.HostHeader), '-sni-name', $probeGroup.HostName)
            }
            if (Test-Path -LiteralPath $groupOutput -PathType Leaf) { Remove-Item -LiteralPath $groupOutput -Force }
            $httpxResult = Invoke-LoggedProcess -FilePath $httpx -ArgumentList $httpxArgs -Name ('httpx-{0:D3}' -f $groupCounter) -TimeoutSeconds $CommandTimeoutSeconds -ContinueOnError -ClearEnvironmentVariables $proxyEnvironmentNames
            if ($httpxResult.Success) {
                if (Test-Path -LiteralPath $groupOutput -PathType Leaf) {
                    $null = Add-WebProbeJsonLines -SourcePath $groupOutput -DestinationPath $httpxOutput -Probes $probeGroup.Probes
                }
                else {
                    Write-Log -Level ERROR -Message ("httpx exited successfully but did not create its requested JSONL output: {0}" -f $groupOutput)
                }
            }
            else {
                Move-FailedWebOutputAside -Path $groupOutput
            }
        }
    }
    else {
        $script:Manifest.parameters['webBackend'] = 'native-and-curl'
        Write-RunManifest
        Write-Log -Level WARN -Message 'httpx was not found; using native HTTP HEAD probes and curl --insecure for every HTTPS or frozen hostname/SNI probe when curl.exe is available.'
        Invoke-NativeWebProbe -Probes $probes | Out-Null
    }

    if ($EnableNuclei) {
        $nuclei = Find-Tool -Name 'nuclei.exe'
        if (-not $nuclei) {
            Write-Log -Level ERROR -Message 'Nuclei was explicitly enabled but nuclei.exe was not found.'
        }
        else {
            $templateStatus = Get-NucleiTemplateStatus
            Save-NucleiTemplateMetadata -Status $templateStatus
            if (-not $templateStatus.Ready) {
                Write-Log -Level ERROR -Message ("Nuclei was enabled, but no readable local templates exist under {0}. Run -Action Install -InstallTool nuclei before the competition." -f $NucleiTemplatesDirectory)
            }
            else {
                Write-Log -Level INFO -Message ("Using explicit offline-ready Nuclei templates: version {0}, {1} YAML template(s), {2} total input file(s), tree SHA-256 {3}, {4}." -f $templateStatus.Version, $templateStatus.TemplateCount, $templateStatus.TemplateTreeFileCount, $templateStatus.TemplateTreeSha256, $templateStatus.Path)
                $nucleiOutput = Join-Path $script:RawDirectory 'nuclei.jsonl'
                Write-Utf8File -Path $nucleiOutput -Content ''
                $templateTreeStable = Test-NucleiTemplateTreeStable -ExpectedStatus $templateStatus
                $script:Manifest.tools['nucleiTemplates']['scanDigestValidatedBefore'] = [bool]$templateTreeStable
                Write-RunManifest
                if ($templateTreeStable) {
                    $groupCounter = 0
                    foreach ($probeGroup in $probeGroups) {
                        $groupCounter++
                        $groupInput = Join-Path $script:ScopeDirectory ('nuclei-input-{0:D3}.txt' -f $groupCounter)
                        $groupOutput = Join-Path $script:RawDirectory ('nuclei-{0:D3}.jsonl' -f $groupCounter)
                        $groupUrls = @($probeGroup.Probes | Select-Object -ExpandProperty ConnectionUrl -Unique | Sort-Object)
                        Write-Utf8File -Path $groupInput -Content (($groupUrls -join [Environment]::NewLine) + [Environment]::NewLine)
                        $nucleiArgs = @('-config', $nucleiConfigPath, '-no-stdin', '-l', $groupInput, '-templates', $templateStatus.Path, '-type', 'http,ssl', '-disable-unsigned-templates', '-jsonl', '-o', $groupOutput, '-rate-limit', [string]$WebRateLimit, '-bulk-size', '10', '-concurrency', ([string][Math]::Min($Throttle, 20)), '-timeout', '10', '-retries', '1', '-exclude-tags', 'dos,fuzz,intrusive,headless,bruteforce,default-login', '-no-interactsh', '-disable-redirects', '-disable-update-check', '-stats', '-verbose', '-no-color')
                        if ($probeGroup.HostName) {
                            $nucleiArgs += @('-H', ('Host: {0}' -f $probeGroup.HostHeader), '-sni', $probeGroup.HostName)
                        }
                        if (Test-Path -LiteralPath $groupOutput -PathType Leaf) { Remove-Item -LiteralPath $groupOutput -Force }
                        $nucleiResult = Invoke-LoggedProcess -FilePath $nuclei -ArgumentList $nucleiArgs -Name ('nuclei-safe-templates-{0:D3}' -f $groupCounter) -TimeoutSeconds $CommandTimeoutSeconds -ContinueOnError -ClearEnvironmentVariables $proxyEnvironmentNames
                        if ($nucleiResult.Success) {
                            if (Test-Path -LiteralPath $groupOutput -PathType Leaf) {
                                $null = Add-WebProbeJsonLines -SourcePath $groupOutput -DestinationPath $nucleiOutput -Probes $probeGroup.Probes
                            }
                            else {
                                Write-Log -Level ERROR -Message ("Nuclei exited successfully but did not create its requested JSONL output: {0}" -f $groupOutput)
                            }
                        }
                        else {
                            Move-FailedWebOutputAside -Path $groupOutput
                        }
                    }
                    $templateTreeStable = Test-NucleiTemplateTreeStable -ExpectedStatus $templateStatus
                }
                $script:Manifest.tools['nucleiTemplates']['scanDigestValidatedAfter'] = [bool]$templateTreeStable
                Write-RunManifest
            }
        }
    }

    if ($EnableFfuf) {
        if (-not $Wordlist) { throw '-Wordlist is required when -EnableFfuf is used.' }
        $wordlistPath = Get-FullPath -Path $Wordlist
        if (-not (Test-Path -LiteralPath $wordlistPath -PathType Leaf)) { throw "Wordlist not found: $wordlistPath" }
        $ffuf = Find-Tool -Name 'ffuf.exe'
        if (-not $ffuf) {
            Write-Log -Level ERROR -Message 'ffuf was explicitly enabled but ffuf.exe was not found.'
        }
        else {
            $frozenWordlistPath = New-FrozenFfufWordlist -SourcePath $wordlistPath
            $frozenWordlistMetadata = $script:Manifest.tools['ffufWordlist']
            $frozenWordlistSha256 = [string]$frozenWordlistMetadata.sha256
            $frozenWordlistSize = [int64]$frozenWordlistMetadata.sizeBytes
            $counter = 0
            foreach ($probe in $probes) {
                $counter++
                if (-not (Test-FrozenFfufWordlistIntegrity -Path $frozenWordlistPath -ExpectedSha256 $frozenWordlistSha256 -ExpectedSize $frozenWordlistSize -Moment ("immediately before ffuf probe {0}" -f $counter))) {
                    break
                }
                $output = Join-Path $script:RawDirectory ('ffuf_{0:D3}.json' -f $counter)
                $fuzzUrl = $probe.ConnectionUrl.TrimEnd('/') + '/FUZZ'
                $ffufArgs = @('-config', $ffufConfigPath, '-u', $fuzzUrl, '-w', $frozenWordlistPath, '-rate', [string]$WebRateLimit, '-t', ([string][Math]::Min($Throttle, 40)), '-timeout', '10', '-ac', '-of', 'json', '-o', $output, '-noninteractive')
                if ($probe.HostName) {
                    $ffufArgs += @('-H', ('Host: {0}' -f $probe.HostHeader), '-sni', $probe.HostName)
                }
                if (Test-Path -LiteralPath $output -PathType Leaf) { Remove-Item -LiteralPath $output -Force }
                $ffufResult = Invoke-LoggedProcess -FilePath $ffuf -ArgumentList $ffufArgs -Name ('ffuf-{0:D3}' -f $counter) -TimeoutSeconds $CommandTimeoutSeconds -ContinueOnError -ClearEnvironmentVariables $proxyEnvironmentNames
                $wordlistStableAfterProbe = Test-FrozenFfufWordlistIntegrity -Path $frozenWordlistPath -ExpectedSha256 $frozenWordlistSha256 -ExpectedSize $frozenWordlistSize -Moment ("immediately after ffuf probe {0}" -f $counter)
                if (-not $wordlistStableAfterProbe) {
                    Move-FailedWebOutputAside -Path $output
                    break
                }
                elseif (-not $ffufResult.Success) {
                    Move-FailedWebOutputAside -Path $output
                }
                elseif (-not (Test-Path -LiteralPath $output -PathType Leaf)) {
                    Write-Log -Level ERROR -Message ("ffuf exited successfully but did not create its requested JSON output: {0}" -f $output)
                }
                else {
                    try {
                        [void](Assert-FfufJsonOutput -Path $output)
                    }
                    catch {
                        Write-Log -Level ERROR -Message ("ffuf exited successfully but its output is not a valid ffuf JSON results envelope ({0}): {1}" -f $output, $_.Exception.Message)
                        Move-FailedWebOutputAside -Path $output
                    }
                }
            }
        }
    }
    Set-StageStatus -Name 'web' -Status $(if ($script:ErrorCount -gt $stageErrorStart) { 'partial' } else { 'complete' }) -Detail ("{0} probe(s); {1} frozen hostname mapping(s)" -f $probes.Count, $hostnameProbeCount)
}

function Confirm-AdDomainAuthorization {
    param([Parameter(Mandatory = $true)][string]$DetectedDomain)
    $normalizedDomain = $DetectedDomain.Trim().TrimEnd('.').ToLowerInvariant()
    $domainPattern = '^(?=.{1,253}$)[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)*$'
    if ($normalizedDomain -notmatch $domainPattern) {
        throw "The detected AD domain name is invalid: $DetectedDomain"
    }
    if ([string]::IsNullOrWhiteSpace($AuthorizedAdDomain)) {
        throw '-AuthorizedAdDomain is required when -EnableAd is used.'
    }
    $normalizedAuthorizedDomain = $AuthorizedAdDomain.Trim().TrimEnd('.').ToLowerInvariant()
    if ($normalizedAuthorizedDomain -cne $normalizedDomain) {
        throw "The joined AD domain '$normalizedDomain' does not exactly match -AuthorizedAdDomain '$normalizedAuthorizedDomain'."
    }
    if ($AcknowledgeAdDomain) { return $normalizedDomain }
    if ($NonInteractive) {
        throw '-AcknowledgeAdDomain is required for non-interactive AD collection.'
    }
    Write-Host ''
    Write-Host ("AD metadata collection will query only an in-scope domain controller for {0}." -f $normalizedDomain) -ForegroundColor Yellow
    $answer = Read-Host ("Type AD:{0} to acknowledge that this domain is authorized" -f $normalizedDomain)
    if ($answer -cne ("AD:{0}" -f $normalizedDomain)) {
        throw 'AD domain authorization was not acknowledged.'
    }
    return $normalizedDomain
}

function Get-ApprovedDomainControllers {
    param(
        [Parameter(Mandatory = $true)][string]$DomainName,
        [Parameter(Mandatory = $true)]$Scope,
        [Parameter(Mandatory = $true)][string]$EvidencePath
    )
    $allowedSet = New-AllowedAddressSet -Addresses $Scope.Targets
    $records = New-Object System.Collections.Generic.List[System.Object]
    $approved = New-Object System.Collections.Generic.List[System.Object]
    if (-not (Get-Command Resolve-DnsName -ErrorAction SilentlyContinue)) {
        throw 'Resolve-DnsName is unavailable; refusing AD collection because domain-controller endpoints cannot be frozen and checked against scope.'
    }

    $queryName = '_ldap._tcp.dc._msdcs.{0}' -f $DomainName
    $srvResults = @(Resolve-DnsName $queryName -Type SRV -DnsOnly -ErrorAction Stop)
    $controllerNames = @($srvResults | ForEach-Object { [string]$_.NameTarget } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { $_.Trim().TrimEnd('.').ToLowerInvariant() } |
        Sort-Object -Unique)
    if ($controllerNames.Count -eq 0) {
        throw "No domain controllers were returned for $queryName."
    }

    foreach ($controllerName in $controllerNames) {
        try {
            $resolvedAddresses = @([Net.Dns]::GetHostAddresses($controllerName) |
                Where-Object { $_.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork } |
                ForEach-Object { $_.ToString() } | Sort-Object -Unique)
            if ($resolvedAddresses.Count -eq 0) { throw 'no IPv4 addresses were returned' }
            foreach ($address in $resolvedAddresses) {
                $inScope = $allowedSet.Contains($address)
                $record = [pscustomobject]@{
                    DomainController = $controllerName
                    Address = $address
                    InScope = $inScope
                    ResolutionError = $null
                }
                [void]$records.Add($record)
                if ($inScope) { [void]$approved.Add($record) }
            }
        }
        catch {
            [void]$records.Add([pscustomobject]@{
                DomainController = $controllerName
                Address = $null
                InScope = $false
                ResolutionError = $_.Exception.Message
            })
        }
    }
    Write-Utf8File -Path $EvidencePath -Content ($records.ToArray() | ConvertTo-Json -Depth 5)
    $rejectedCount = @($records | Where-Object { -not $_.InScope }).Count
    if ($rejectedCount -gt 0) {
        Write-Log -Level WARN -Message ("Skipped {0} resolved/error domain-controller endpoint(s) that were not frozen in scope; see {1}." -f $rejectedCount, $EvidencePath)
    }
    return @($approved | Sort-Object Address, DomainController -Unique)
}

function Invoke-AdMetadataCollection {
    param([Parameter(Mandatory = $true)]$Scope)
    $stageErrorStart = $script:ErrorCount
    $collectorFailureStart = $script:CollectorFailureCount
    Set-StageStatus -Name 'activeDirectory' -Status 'running'
    $adDirectory = Join-Path $script:RawDirectory 'active-directory'
    if (-not (Test-Path -LiteralPath $adDirectory)) { [void](New-Item -ItemType Directory -Path $adDirectory -Force) }
    try {
        $computerSystem = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
    }
    catch {
        Write-Log -Level ERROR -Message ("Could not determine the local AD domain: {0}" -f $_.Exception.Message)
        Set-StageStatus -Name 'activeDirectory' -Status 'failed' -Detail 'Could not determine local domain membership'
        return
    }
    if (-not $computerSystem.PartOfDomain) {
        Write-Log -Level WARN -Message 'This workstation is not domain joined; authenticated AD metadata collection was skipped.'
        Set-StageStatus -Name 'activeDirectory' -Status 'skipped' -Detail 'Workstation is not domain joined'
        return
    }
    try {
        $domainName = Confirm-AdDomainAuthorization -DetectedDomain ([string]$computerSystem.Domain)
    }
    catch {
        Write-Log -Level ERROR -Message ("AD metadata collection was refused before contacting a domain controller: {0}" -f $_.Exception.Message)
        Set-StageStatus -Name 'activeDirectory' -Status 'failed' -Detail $_.Exception.Message
        return
    }

    $dcEvidencePath = Join-Path $adDirectory 'domain-controller-resolution.json'
    try {
        $approvedControllers = @(Get-ApprovedDomainControllers -DomainName $domainName -Scope $Scope -EvidencePath $dcEvidencePath)
    }
    catch {
        Write-Log -Level ERROR -Message ("Could not identify a scope-approved domain controller: {0}" -f $_.Exception.Message)
        Set-StageStatus -Name 'activeDirectory' -Status 'failed' -Detail 'No scope-approved domain controller'
        return
    }
    if ($approvedControllers.Count -eq 0) {
        Write-Log -Level ERROR -Message ("No resolved domain controller for {0} is present in frozen scope. AD collection was skipped." -f $domainName)
        Set-StageStatus -Name 'activeDirectory' -Status 'failed' -Detail 'All resolved domain controllers were outside frozen scope'
        return
    }
    $selectedController = $approvedControllers | Select-Object -First 1
    $dcAddress = [string]$selectedController.Address
    $allowedSet = New-AllowedAddressSet -Addresses $Scope.Targets
    if (-not $allowedSet.Contains($dcAddress)) {
        Write-Log -Level ERROR -Message 'The selected domain-controller address failed the final frozen-scope check; AD collection was skipped.'
        Set-StageStatus -Name 'activeDirectory' -Status 'failed' -Detail 'Final domain-controller scope validation failed'
        return
    }
    Write-Log -Level INFO -Message ("Collecting read-only metadata for authorized domain {0} through scope-approved DC {1} ({2})." -f $domainName, $selectedController.DomainController, $dcAddress)
    $script:Manifest.parameters['authorizedAdDomain'] = $domainName
    $script:Manifest.parameters['selectedAdDomainController'] = $dcAddress
    Write-RunManifest

    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        Write-Log -Level WARN -Message 'The ActiveDirectory RSAT module is unavailable; LDAP metadata exports were skipped without contacting a domain controller.'
        Set-StageStatus -Name 'activeDirectory' -Status 'partial' -Detail 'RSAT ActiveDirectory module not found'
        return
    }
    Import-Module ActiveDirectory -ErrorAction Stop
    Invoke-Collector -Name 'forest' -Directory $adDirectory -ScriptBlock { Get-ADForest -Identity $domainName -Server $dcAddress } | Out-Null
    Invoke-Collector -Name 'domain' -Directory $adDirectory -ScriptBlock { Get-ADDomain -Identity $domainName -Server $dcAddress } | Out-Null
    Invoke-Collector -Name 'domain-controllers' -Directory $adDirectory -ScriptBlock { Get-ADDomainController -Filter * -Server $dcAddress } | Out-Null
    Invoke-Collector -Name 'trusts' -Directory $adDirectory -ScriptBlock { Get-ADTrust -Filter * -Server $dcAddress } | Out-Null
    Invoke-Collector -Name 'default-password-policy' -Directory $adDirectory -ScriptBlock { Get-ADDefaultDomainPasswordPolicy -Identity $domainName -Server $dcAddress } | Out-Null
    Invoke-Collector -Name 'fine-grained-password-policies' -Directory $adDirectory -ScriptBlock { Get-ADFineGrainedPasswordPolicy -Filter * -Server $dcAddress } | Out-Null
    Invoke-Collector -Name 'organizational-units' -Directory $adDirectory -ScriptBlock { Get-ADOrganizationalUnit -Filter * -Server $dcAddress -ResultSetSize $AdObjectLimit -Properties ProtectedFromAccidentalDeletion } | Out-Null
    Invoke-Collector -Name 'users' -Directory $adDirectory -ScriptBlock {
        Get-ADUser -Filter * -Server $dcAddress -ResultSetSize $AdObjectLimit -Properties Enabled, LastLogonDate, PasswordLastSet, PasswordNeverExpires, PasswordNotRequired, DoesNotRequirePreAuth, TrustedForDelegation, ServicePrincipalName, AdminCount |
            Select-Object SamAccountName, DistinguishedName, Enabled, LastLogonDate, PasswordLastSet, PasswordNeverExpires, PasswordNotRequired, DoesNotRequirePreAuth, TrustedForDelegation, ServicePrincipalName, AdminCount
    } | Out-Null
    Invoke-Collector -Name 'computers' -Directory $adDirectory -ScriptBlock {
        Get-ADComputer -Filter * -Server $dcAddress -ResultSetSize $AdObjectLimit -Properties DNSHostName, OperatingSystem, OperatingSystemVersion, LastLogonDate, TrustedForDelegation, msDS-AllowedToDelegateTo |
            Select-Object Name, DNSHostName, DistinguishedName, Enabled, OperatingSystem, OperatingSystemVersion, LastLogonDate, TrustedForDelegation, msDS-AllowedToDelegateTo
    } | Out-Null
    Invoke-Collector -Name 'groups' -Directory $adDirectory -ScriptBlock {
        Get-ADGroup -Filter * -Server $dcAddress -ResultSetSize $AdObjectLimit -Properties GroupCategory, GroupScope, AdminCount, Members |
            Select-Object Name, SamAccountName, DistinguishedName, GroupCategory, GroupScope, AdminCount, Members
    } | Out-Null
    if (Get-Module -ListAvailable -Name GroupPolicy) {
        Import-Module GroupPolicy -ErrorAction SilentlyContinue
        Invoke-Collector -Name 'group-policy-objects' -Directory $adDirectory -ScriptBlock { Get-GPO -All -Domain $domainName -Server $dcAddress | Select-Object DisplayName, Id, GpoStatus, CreationTime, ModificationTime, Owner } | Out-Null
    }
    $status = if ($script:ErrorCount -gt $stageErrorStart -or $script:CollectorFailureCount -gt $collectorFailureStart) { 'partial' } else { 'complete' }
    Set-StageStatus -Name 'activeDirectory' -Status $status -Detail ("Domain {0}; DC {1}; object cap {2}" -f $domainName, $dcAddress, $AdObjectLimit)
}

function ConvertTo-HtmlText {
    param($Value)
    if ($null -eq $Value) { return '' }
    return [Net.WebUtility]::HtmlEncode([string]$Value)
}

function Read-JsonLines {
    param([Parameter(Mandatory = $true)][string]$Path)
    $items = New-Object System.Collections.Generic.List[System.Object]
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @() }
    foreach ($line in Read-Utf8Lines -Path $Path) {
        if (-not $line.Trim()) { continue }
        try { [void]$items.Add(($line | ConvertFrom-Json)) }
        catch { Write-Log -Level DEBUG -Message ("Skipped malformed JSONL record in {0}: {1}" -f $Path, $_.Exception.Message) }
    }
    return $items.ToArray()
}

function Get-RunHistoryProvenance {
    $manifestRecords = New-Object System.Collections.Generic.List[System.Object]
    $processFailureCount = 0
    foreach ($manifestFile in @(Get-ChildItem -LiteralPath $script:RunRoot -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^(?:run|resume|report)-manifest(?:_.+)?\.json$' } |
        Sort-Object Name)) {
        try {
            $manifestData = (Read-Utf8File -Path $manifestFile.FullName) | ConvertFrom-Json
            $exitCodeProperty = $manifestData.PSObject.Properties['exitCode']
            $actionProperty = $manifestData.PSObject.Properties['action']
            $startedProperty = $manifestData.PSObject.Properties['startedUtc']
            $stageFailures = New-Object System.Collections.Generic.List[System.String]
            $stagesProperty = $manifestData.PSObject.Properties['stages']
            if ($stagesProperty -and $stagesProperty.Value) {
                foreach ($stageProperty in $stagesProperty.Value.PSObject.Properties) {
                    $statusProperty = $stageProperty.Value.PSObject.Properties['status']
                    if ($statusProperty -and [string]$statusProperty.Value -match '^(?i:partial|failed)$') {
                        [void]$stageFailures.Add(('{0}:{1}' -f $stageProperty.Name, [string]$statusProperty.Value))
                    }
                }
            }
            $numericExitCode = $null
            if ($exitCodeProperty -and $null -ne $exitCodeProperty.Value) { $numericExitCode = [int]$exitCodeProperty.Value }
            [void]$manifestRecords.Add([pscustomobject]@{
                File = $manifestFile.Name
                Action = $(if ($actionProperty) { [string]$actionProperty.Value } else { '' })
                StartedUtc = $(if ($startedProperty) { [string]$startedProperty.Value } else { '' })
                ExitCode = $numericExitCode
                FailedOrPartialStages = $stageFailures.ToArray()
                HasErrors = (($null -ne $numericExitCode -and $numericExitCode -ne 0) -or $stageFailures.Count -gt 0)
                ParseError = $null
            })
        }
        catch {
            [void]$manifestRecords.Add([pscustomobject]@{
                File = $manifestFile.Name
                Action = ''
                StartedUtc = ''
                ExitCode = $null
                FailedOrPartialStages = @()
                HasErrors = $true
                ParseError = $_.Exception.Message
            })
        }
    }
    foreach ($eventFile in @(Get-ChildItem -LiteralPath $script:LogDirectory -Filter 'events_*.jsonl' -File -ErrorAction SilentlyContinue)) {
        foreach ($processRecord in @(Read-JsonLines -Path $eventFile.FullName)) {
            $successProperty = $processRecord.PSObject.Properties['success']
            if ($successProperty -and -not [bool]$successProperty.Value) { $processFailureCount++ }
        }
    }
    $manifestErrorCount = @($manifestRecords | Where-Object { $_.HasErrors }).Count
    return [pscustomobject]@{
        Manifests = $manifestRecords.ToArray()
        ManifestErrorCount = $manifestErrorCount
        ProcessFailureCount = $processFailureCount
        HasHistoricalErrors = ($manifestErrorCount -gt 0 -or $processFailureCount -gt 0)
    }
}

function Invoke-ReportAction {
    $stageErrorStart = $script:ErrorCount
    Set-StageStatus -Name 'report' -Status 'running'
    $runHistory = Get-RunHistoryProvenance
    $scopeTargets = @()
    $scopePath = Join-Path $script:ScopeDirectory 'targets.txt'
    if (Test-Path -LiteralPath $scopePath) {
        $scopeTargets = @((Read-Utf8Lines -Path $scopePath) | ForEach-Object {
            $parsedAddress = $null
            if ([Net.IPAddress]::TryParse($_.Trim(), [ref]$parsedAddress) -and
                $parsedAddress.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork) {
                $parsedAddress.ToString()
            }
        } | Sort-Object -Unique)
    }
    if ($scopeTargets.Count -eq 0) {
        Write-Log -Level WARN -Message 'The run has no valid frozen IPv4 scope file; parsed network results will be excluded from the report.'
    }

    $xmlProvenance = New-Object System.Collections.Generic.List[System.Object]
    $attemptedNmapFiles = New-Object -TypeName 'System.Collections.Generic.HashSet[System.String]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($eventFile in @(Get-ChildItem -LiteralPath $script:LogDirectory -Filter 'events_*.jsonl' -File -ErrorAction SilentlyContinue)) {
        foreach ($processRecord in @(Read-JsonLines -Path $eventFile.FullName)) {
            $processNameProperty = $processRecord.PSObject.Properties['name']
            if (-not $processNameProperty) { continue }
            switch -Regex ([string]$processNameProperty.Value) {
                '^nmap-discovery$' { [void]$attemptedNmapFiles.Add('nmap-discovery.xml'); break }
                '^nmap-tcp(?:-connect-fallback)?$' { [void]$attemptedNmapFiles.Add('nmap-tcp.xml'); break }
                '^nmap-services(?:-connect-fallback)?$' { [void]$attemptedNmapFiles.Add('nmap-services.xml'); break }
                '^nmap-udp$' { [void]$attemptedNmapFiles.Add('nmap-udp.xml'); break }
            }
        }
    }
    $invalidXmlCount = 0
    foreach ($xmlName in @('nmap-discovery.xml', 'nmap-tcp.xml', 'nmap-services.xml', 'nmap-udp.xml')) {
        $xmlPath = Join-Path $script:RawDirectory $xmlName
        $exists = Test-Path -LiteralPath $xmlPath -PathType Leaf
        $expected = $attemptedNmapFiles.Contains($xmlName)
        $successful = $false
        $sha256 = $null
        if ($exists) {
            $sha256 = (Get-FileHash -LiteralPath $xmlPath -Algorithm SHA256).Hash
            $successful = Test-NmapXmlSuccess -Path $xmlPath
            if (-not $successful) { $invalidXmlCount++ }
        }
        elseif ($expected) {
            $invalidXmlCount++
            Write-Log -Level WARN -Message ("Expected Nmap XML is missing for an attempted phase: {0}" -f $xmlName)
        }
        [void]$xmlProvenance.Add([pscustomobject]@{ File = $xmlName; Expected = $expected; Exists = $exists; SuccessfulNmapRun = $successful; Sha256 = $sha256 })
    }
    $tcpInventory = @(Read-NmapXml -Path (Join-Path $script:RawDirectory 'nmap-tcp.xml') -AllowedAddresses $scopeTargets)
    $serviceInventory = @(Read-NmapXml -Path (Join-Path $script:RawDirectory 'nmap-services.xml') -AllowedAddresses $scopeTargets)
    $tcpInventory = @(Merge-NmapInventory -Baseline $tcpInventory -Enrichment $serviceInventory)
    $udpInventory = @(Read-NmapXml -Path (Join-Path $script:RawDirectory 'nmap-udp.xml') -AllowedAddresses $scopeTargets)
    $deduped = @(Merge-NmapInventory -Baseline $tcpInventory -Enrichment $udpInventory)

    $servicesCsv = Join-Path $script:NormalizedDirectory 'services.csv'
    if ($deduped.Count -gt 0) {
        $deduped | Export-Csv -LiteralPath $servicesCsv -NoTypeInformation -Encoding UTF8
    }
    else {
        Write-Utf8File -Path $servicesCsv -Content 'Address,HostName,Protocol,Port,State,Reason,Service,Product,Version,ExtraInfo,Tunnel,Scripts,HostScripts,OsMatch,SourceXml'
    }

    $openHosts = @($deduped | Select-Object -ExpandProperty Address -Unique)
    $hostSummary = foreach ($address in $scopeTargets) {
        $hostRecords = @($deduped | Where-Object { $_.Address -eq $address })
        [pscustomobject]@{
            Address = $address
            OpenPortCount = $hostRecords.Count
            OpenPorts = (($hostRecords | ForEach-Object { '{0}/{1}' -f $_.Port, $_.Protocol }) -join ', ')
        }
    }
    $hostsCsv = Join-Path $script:NormalizedDirectory 'hosts.csv'
    if (@($hostSummary).Count -gt 0) {
        @($hostSummary) | Export-Csv -LiteralPath $hostsCsv -NoTypeInformation -Encoding UTF8
    }
    else {
        Write-Utf8File -Path $hostsCsv -Content 'Address,OpenPortCount,OpenPorts'
    }

    # Host-level NSE/OS evidence keyed on address, so SMB share and signing
    # findings are not buried in whichever port row happened to carry them.
    $hostEvidence = foreach ($evidenceGroup in @($deduped | Where-Object { -not ([string]::IsNullOrWhiteSpace([string]$_.HostScripts) -and [string]::IsNullOrWhiteSpace([string]$_.OsMatch)) } | Group-Object Address)) {
        $first = @($evidenceGroup.Group)[0]
        [pscustomobject]@{
            Address = [string]$evidenceGroup.Name
            HostName = [string]$first.HostName
            OsMatch = [string]$first.OsMatch
            HostScripts = [string]$first.HostScripts
        }
    }
    $hostScriptsCsv = Join-Path $script:NormalizedDirectory 'host-scripts.csv'
    if (@($hostEvidence).Count -gt 0) {
        @($hostEvidence) | Sort-Object Address | Export-Csv -LiteralPath $hostScriptsCsv -NoTypeInformation -Encoding UTF8
    }
    else {
        Write-Utf8File -Path $hostScriptsCsv -Content 'Address,HostName,OsMatch,HostScripts'
    }

    $webRecords = @(Read-JsonLines -Path (Join-Path $script:RawDirectory 'httpx.jsonl'))
    if ($webRecords.Count -gt 0) {
        $webRecords = @(Select-JsonRecordsWithinScope -Records $webRecords -AllowedAddresses $scopeTargets -SourceName 'httpx.jsonl')
    }
    else {
        $webRecords = @(Select-JsonRecordsWithinScope -Records @(Read-JsonLines -Path (Join-Path $script:RawDirectory 'native-web.jsonl')) -AllowedAddresses $scopeTargets -SourceName 'native-web.jsonl')
    }
    $webCsv = Join-Path $script:NormalizedDirectory 'web.csv'
    if ($webRecords.Count -gt 0) {
        $webRecords | Export-Csv -LiteralPath $webCsv -NoTypeInformation -Encoding UTF8
    }
    else {
        Write-Utf8File -Path $webCsv -Content 'url,status_code,title,server,technology,location'
    }
    $nucleiRecords = @(Select-JsonRecordsWithinScope -Records @(Read-JsonLines -Path (Join-Path $script:RawDirectory 'nuclei.jsonl')) -AllowedAddresses $scopeTargets -SourceName 'nuclei.jsonl')
    $nucleiCsv = Join-Path $script:NormalizedDirectory 'nuclei.csv'
    if ($nucleiRecords.Count -gt 0) {
        $nucleiRecords | Export-Csv -LiteralPath $nucleiCsv -NoTypeInformation -Encoding UTF8
    }
    else {
        Write-Utf8File -Path $nucleiCsv -Content 'severity,template_id,name,matched_at'
    }

    $reportProvenance = [ordered]@{
        generatedUtc = [DateTime]::UtcNow.ToString('o')
        scopeFile = $scopePath
        scopeSha256 = $(if (Test-Path -LiteralPath $scopePath -PathType Leaf) { (Get-FileHash -LiteralPath $scopePath -Algorithm SHA256).Hash } else { $null })
        allowedAddresses = $scopeTargets
        nmapXml = $xmlProvenance.ToArray()
        runHistory = $runHistory
        existingChecksumStatus = $script:ExistingChecksumStatus
        checksumVerificationIssues = @($script:ChecksumVerificationIssues)
        filtering = 'Only IPv4 endpoints present in the frozen scope file are included in normalized report data.'
    }
    Write-Utf8File -Path (Join-Path $script:NormalizedDirectory 'report-provenance.json') -Content ($reportProvenance | ConvertTo-Json -Depth 8)

    $summary = [ordered]@{
        generatedUtc = [DateTime]::UtcNow.ToString('o')
        scopedTargets = $scopeTargets.Count
        hostsWithOpenPorts = $openHosts.Count
        openServices = $deduped.Count
        webEndpoints = $webRecords.Count
        nucleiResults = $nucleiRecords.Count
        historicalManifestErrors = $runHistory.ManifestErrorCount
        historicalProcessFailures = $runHistory.ProcessFailureCount
        invalidNmapXml = $invalidXmlCount
        currentReportErrors = [Math]::Max(0, ($script:ErrorCount - $stageErrorStart))
        evidenceIntegrityFailure = [bool]$script:EvidenceIntegrityFailure
        evidenceIntegrityUnverified = [bool]($script:ExistingChecksumStatus -eq 'missing')
        partialErrors = [bool]($script:HadErrors -or $script:EvidenceIntegrityFailure -or $script:ExistingChecksumStatus -eq 'missing' -or $invalidXmlCount -gt 0 -or $runHistory.HasHistoricalErrors)
    }
    Write-Utf8File -Path (Join-Path $script:NormalizedDirectory 'summary.json') -Content ($summary | ConvertTo-Json -Depth 5)

    $serviceRows = New-Object System.Text.StringBuilder
    foreach ($record in $deduped) {
        [void]$serviceRows.AppendLine(('<tr><td>{0}</td><td>{1}/{2}</td><td>{3}</td><td>{4}</td><td>{5}</td><td class="scripts">{6}</td></tr>' -f
            (ConvertTo-HtmlText $record.Address), (ConvertTo-HtmlText $record.Port), (ConvertTo-HtmlText $record.Protocol),
            (ConvertTo-HtmlText $record.Service), (ConvertTo-HtmlText $record.Product), (ConvertTo-HtmlText $record.Version),
            (ConvertTo-HtmlText $record.Scripts)))
    }
    if ($serviceRows.Length -eq 0) { [void]$serviceRows.AppendLine('<tr><td colspan="6">No open services were parsed.</td></tr>') }

    $hostEvidenceRows = New-Object System.Text.StringBuilder
    foreach ($record in @($hostEvidence | Sort-Object Address)) {
        [void]$hostEvidenceRows.AppendLine(('<tr><td>{0}</td><td>{1}</td><td>{2}</td><td class="scripts">{3}</td></tr>' -f
            (ConvertTo-HtmlText $record.Address), (ConvertTo-HtmlText $record.HostName),
            (ConvertTo-HtmlText $record.OsMatch), (ConvertTo-HtmlText $record.HostScripts)))
    }
    if ($hostEvidenceRows.Length -eq 0) { [void]$hostEvidenceRows.AppendLine('<tr><td colspan="4">No host-level NSE or OS evidence was parsed.</td></tr>') }

    $webRows = New-Object System.Text.StringBuilder
    foreach ($record in $webRecords) {
        $url = if ($record.PSObject.Properties.Name -contains 'cptc_display_url') { $record.cptc_display_url } elseif ($record.PSObject.Properties.Name -contains 'url') { $record.url } else { '' }
        $statusCode = if ($record.PSObject.Properties.Name -contains 'status_code') { $record.status_code } else { '' }
        $title = if ($record.PSObject.Properties.Name -contains 'title') { $record.title } else { '' }
        $server = if ($record.PSObject.Properties.Name -contains 'webserver') { $record.webserver } elseif ($record.PSObject.Properties.Name -contains 'server') { $record.server } else { '' }
        $technology = if ($record.PSObject.Properties.Name -contains 'tech') { @($record.tech) -join ', ' } else { '' }
        $location = if ($record.PSObject.Properties.Name -contains 'location') { $record.location } else { '' }
        [void]$webRows.AppendLine(('<tr><td>{0}</td><td>{1}</td><td>{2}</td><td>{3}</td><td>{4}</td><td>{5}</td></tr>' -f
            (ConvertTo-HtmlText $url), (ConvertTo-HtmlText $statusCode), (ConvertTo-HtmlText $title),
            (ConvertTo-HtmlText $server), (ConvertTo-HtmlText $technology), (ConvertTo-HtmlText $location)))
    }
    if ($webRows.Length -eq 0) { [void]$webRows.AppendLine('<tr><td colspan="6">No web metadata was collected.</td></tr>') }

    $nucleiRows = New-Object System.Text.StringBuilder
    foreach ($record in $nucleiRecords) {
        $templateId = if ($record.PSObject.Properties.Name -contains 'template-id') { $record.'template-id' } else { '' }
        $matched = if ($record.PSObject.Properties.Name -contains 'cptc_display_url') { $record.cptc_display_url } elseif ($record.PSObject.Properties.Name -contains 'matched-at') { $record.'matched-at' } else { '' }
        $name = ''
        $severity = ''
        if ($record.PSObject.Properties.Name -contains 'info' -and $record.info) {
            if ($record.info.PSObject.Properties.Name -contains 'name') { $name = $record.info.name }
            if ($record.info.PSObject.Properties.Name -contains 'severity') { $severity = $record.info.severity }
        }
        [void]$nucleiRows.AppendLine(('<tr><td>{0}</td><td>{1}</td><td>{2}</td><td>{3}</td></tr>' -f
            (ConvertTo-HtmlText $severity), (ConvertTo-HtmlText $templateId), (ConvertTo-HtmlText $name), (ConvertTo-HtmlText $matched)))
    }
    if ($nucleiRows.Length -eq 0) { [void]$nucleiRows.AppendLine('<tr><td colspan="4">Nuclei was not run or returned no results.</td></tr>') }

    $generated = ConvertTo-HtmlText $summary.generatedUtc
    $runName = ConvertTo-HtmlText (Split-Path -Leaf $script:RunRoot)
    $manifestLinkParts = New-Object System.Collections.Generic.List[System.String]
    foreach ($manifestRecord in @($runHistory.Manifests)) {
        $manifestName = [string]$manifestRecord.File
        if ($manifestName -match '^[A-Za-z0-9_.-]+$' -and (Test-Path -LiteralPath (Join-Path $script:RunRoot $manifestName) -PathType Leaf)) {
            [void]$manifestLinkParts.Add(('<a href="../{0}">{1}</a>' -f (ConvertTo-HtmlText $manifestName), (ConvertTo-HtmlText $manifestName)))
        }
    }
    $manifestLinks = if ($manifestLinkParts.Count -gt 0) { $manifestLinkParts.ToArray() -join ' | ' } else { 'No manifest files were present.' }
    $partialBanner = if ($summary.partialErrors) {
        '<div class="alert"><strong>Partial, unverified, or error evidence:</strong> the prior checksum baseline may be missing or invalid, or current errors, invalid Nmap XML, failed processes, or partial/failed historical stages were recorded. Review the manifests, process logs, and report provenance before relying on these results.</div>'
    }
    else { '' }
    $html = @"
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>CPTC Windows Enumeration Report</title>
<style>
body{font-family:Segoe UI,Arial,sans-serif;margin:0;background:#0d1117;color:#e6edf3}header,main{max-width:1400px;margin:auto;padding:24px}h1,h2{color:#f0f6fc}.cards{display:flex;flex-wrap:wrap;gap:12px}.card{background:#161b22;border:1px solid #30363d;border-radius:8px;padding:16px;min-width:150px}.number{font-size:2em;font-weight:700;color:#58a6ff}.alert{margin:16px 0;padding:14px;border:1px solid #d29922;border-radius:8px;background:#3d2f00;color:#fff3bf}table{width:100%;border-collapse:collapse;background:#161b22;margin-bottom:28px}th,td{border:1px solid #30363d;padding:8px;text-align:left;vertical-align:top}th{background:#21262d;position:sticky;top:0}.scripts{max-width:520px;white-space:pre-wrap;word-break:break-word}a{color:#58a6ff}code{color:#d2a8ff}.muted{color:#8b949e}</style>
</head><body><header><h1>CPTC Windows Enumeration Report</h1><div class="muted">Run <code>$runName</code> generated $generated UTC</div></header><main>
$partialBanner
<div class="cards">
<div class="card"><div class="number">$($summary.scopedTargets)</div>Scoped targets</div>
<div class="card"><div class="number">$($summary.hostsWithOpenPorts)</div>Hosts with open ports</div>
<div class="card"><div class="number">$($summary.openServices)</div>Open services</div>
<div class="card"><div class="number">$($summary.webEndpoints)</div>Web endpoints</div>
<div class="card"><div class="number">$($summary.nucleiResults)</div>Nuclei results</div>
<div class="card"><div class="number">$($summary.historicalProcessFailures)</div>Recorded process failures</div>
<div class="card"><div class="number">$($summary.historicalManifestErrors)</div>Partial/failed manifests</div>
<div class="card"><div class="number">$($summary.invalidNmapXml)</div>Invalid Nmap XML files</div>
<div class="card"><div class="number">$(if ($summary.evidenceIntegrityFailure) { 'FAIL' } else { ConvertTo-HtmlText $script:ExistingChecksumStatus })</div>Prior evidence integrity</div>
</div>
<p>Evidence: <a href="../normalized/hosts.csv">hosts.csv</a> | <a href="../normalized/services.csv">services.csv</a> | <a href="../normalized/host-scripts.csv">host-scripts.csv</a> | <a href="../normalized/web.csv">web.csv</a> | <a href="../normalized/nuclei.csv">nuclei.csv</a> | <a href="../normalized/report-provenance.json">report provenance</a></p>
<p>Manifests: $manifestLinks</p>
<h2>Open services</h2><table><thead><tr><th>Address</th><th>Port</th><th>Service</th><th>Product</th><th>Version</th><th>NSE output</th></tr></thead><tbody>$($serviceRows.ToString())</tbody></table>
<h2>Host evidence (SMB/OS host scripts)</h2><table><thead><tr><th>Address</th><th>Hostname</th><th>OS match</th><th>Host NSE output</th></tr></thead><tbody>$($hostEvidenceRows.ToString())</tbody></table>
<h2>Web metadata</h2><table><thead><tr><th>URL</th><th>Status</th><th>Title</th><th>Server</th><th>Technology</th><th>Location (not followed)</th></tr></thead><tbody>$($webRows.ToString())</tbody></table>
<h2>Explicit Nuclei results</h2><table><thead><tr><th>Severity</th><th>Template</th><th>Name</th><th>Matched at</th></tr></thead><tbody>$($nucleiRows.ToString())</tbody></table>
</main></body></html>
"@
    $reportPath = Join-Path $script:ReportDirectory 'index.html'
    Write-Utf8File -Path $reportPath -Content $html
    $reportStatus = if ($summary.partialErrors) { 'partial' } else { 'complete' }
    Set-StageStatus -Name 'report' -Status $reportStatus -Detail $reportPath
    Write-Log -Level SUCCESS -Message ("Report written to {0}." -f $reportPath)
}

function Invoke-RunAction {
    $scope = Resolve-Scope
    Confirm-Scope -Scope $scope
    if (-not $script:RootCmdlet.ShouldProcess(("{0} target(s), scope {1}" -f $scope.Count, $scope.Sha256), ("Run {0} enumeration" -f $ScanProfile))) {
        Write-Log -Level INFO -Message 'Enumeration was not executed.'
        return
    }
    Reset-UnverifiedResumeEvidence
    if (-not $SkipLocalInventory) { Invoke-LocalInventory }
    $inventory = @(Invoke-NmapEnumeration -Scope $scope)
    if (-not $SkipWeb) {
        Invoke-WebEnumeration -Inventory $inventory -Scope $scope
    }
    else {
        Move-PriorWebEvidenceAside
        Set-StageStatus -Name 'web' -Status 'skipped' -Detail 'Skipped by -SkipWeb; prior top-level web evidence was archived and excluded'
    }
    if ($EnableAd) { Invoke-AdMetadataCollection -Scope $scope }
    Invoke-ReportAction
}

$exitCode = 0
try {
    Initialize-RunContext -UseExisting:(($Action -eq 'Report') -or ($Action -eq 'Run' -and $Resume))
    Write-Log -Level INFO -Message ("Action={0}; Profile={1}; PowerShell={2}; Administrator={3}" -f $Action, $ScanProfile, $PSVersionTable.PSVersion, (Get-IsAdministrator))
    switch ($Action) {
        'Install' { Invoke-InstallAction }
        'Doctor' { Invoke-DoctorAction }
        'Run' { Invoke-RunAction }
        'Report' { Invoke-ReportAction }
    }
    if ($script:HadErrors) { $exitCode = 2 }
}
catch {
    $exitCode = 1
    $script:HadErrors = $true
    Write-Log -Level ERROR -Message $_.Exception.Message
    if ($script:Manifest) {
        Set-StageStatus -Name 'fatal' -Status 'failed' -Detail $_.Exception.Message
    }
}
finally {
    if ($script:Manifest) {
        $script:Manifest.completedUtc = [DateTime]::UtcNow.ToString('o')
        $script:Manifest.exitCode = $exitCode
        Write-RunManifest
    }
    if ($script:TranscriptStarted) {
        try {
            & {
                $WhatIfPreference = $false
                Stop-Transcript | Out-Null
            }
        }
        catch { }
        $script:TranscriptStarted = $false
    }
    if ($script:SuppressArtifactHashFinalization) {
        Write-Host '[INTEGRITY] Existing-run evidence did not have a verified baseline and was not fully replaced by a successful Resume quarantine; no checksum baseline was generated.' -ForegroundColor Red
    }
    elseif ($script:EvidenceIntegrityFailure) {
        Write-Host '[INTEGRITY] Existing SHA256SUMS.txt failed verification and was preserved byte-for-byte; no replacement checksum baseline was generated.' -ForegroundColor Red
    }
    elseif (-not $script:Manifest) {
        # Initialization failed before this invocation established an evidence
        # manifest. Preserve any prior checksum baseline unchanged.
    }
    else {
        try {
            Write-ArtifactHashes
        }
        catch {
            if ($exitCode -eq 0) { $exitCode = 2 }
            $script:HadErrors = $true
            Write-Log -Level ERROR -Message ("Could not finalize artifact checksums: {0}" -f $_.Exception.Message)
            if ($script:Manifest) {
                $script:Manifest.exitCode = $exitCode
                $script:Manifest.completedUtc = [DateTime]::UtcNow.ToString('o')
                Write-RunManifest
            }
        }
    }
    if ($script:ToolInstallLockStream) {
        try { $script:ToolInstallLockStream.Dispose() } catch { }
        $script:ToolInstallLockStream = $null
    }
    if ($script:RunLockStream) {
        try { $script:RunLockStream.Dispose() } catch { }
        $script:RunLockStream = $null
    }
}

if ($script:RunRoot) {
    Write-Host ("Artifacts: {0}" -f $script:RunRoot)
}
exit $exitCode
