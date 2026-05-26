MS_BUILD?="C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/MSBuild.exe"
PLATFORM?=x64
CONFIG?=Release

all: build

build:
	$(MS_BUILD) _codex_build_check.sln -t:_codex_build_check -nologo -verbosity:minimal -property:Configuration=$(CONFIG) -property:Platform=$(PLATFORM)
