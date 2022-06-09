Program for managing tasks written in Lazarus IDE (Free Pascal).

![](images/screenshot.png)

Still work in progress, but some features already implemented:
- Time tracking
- Marking tasks as completed
- Shows total time spent per day
- Export database to XML
- Filter tasks by name

# Build

Currently only M$ Windows is supported.

You need to have [Free Pascal Compiler (FPC) and Lazarus IDE](https://www.lazarus-ide.org/) installed.

Clone repository with all submodules:

```
git clone https://github.com/artem78/TaskOrganizer.git --recurse-submodules
```

Install additional packages:

- From `packages` directory:
  - LazDatabaseVersioning
  - TrayIconExLazPkg
- From online package manager in IDE:
  - uniqueinstance

[Download SQlite3 library](https://www.sqlite.org/download.html) and put \*.dll to main Lazarus root directory and project directory.

Compile in IDE or from command line:

```
"c:/path/to/lazarus/lazbuild.exe" TasksOrganizer.lpi
```
