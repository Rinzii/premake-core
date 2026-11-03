--
-- tests/test_clang.lua
-- Automated test suite for the GCC toolset interface.
-- Copyright (c) 2009-2013 Jess Perkins and the Premake project
--

	local p = premake
	local suite = test.declare("tools_clang")

	local clang = p.tools.clang
	local project = p.project


--
-- Setup/teardown
--

	local wks, prj, cfg

	function suite.setup()
		wks, prj = test.createWorkspace()
		system "Linux"
	end

	local function prepare()
		cfg = test.getconfig(prj, "Debug")
	end


--
-- Check the selection of tools based on the target system.
--

	function suite.tools_onDefaults()
		prepare()
		test.isequal("clang", clang.gettoolname(cfg, "cc"))
		test.isequal("clang++", clang.gettoolname(cfg, "cxx"))
		test.isequal("ar", clang.gettoolname(cfg, "ar"))
		test.isequal("windres", clang.gettoolname(cfg, "rc"))
	end

	function suite.tools_onWindows()
		system "Windows"
		prepare()
		test.isequal("llvm-ar", clang.gettoolname(cfg, "ar"))
	end

	function suite.tools_onLinkTimeOptimizationViaAPI()
		linktimeoptimization "On"
		prepare()
		test.isequal("clang", clang.gettoolname(cfg, "cc"))
		test.isequal("clang++", clang.gettoolname(cfg, "cxx"))
		test.isequal("llvm-ar", clang.gettoolname(cfg, "ar"))
		test.isequal("windres", clang.gettoolname(cfg, "rc"))
	end

	function suite.tools_onFastLinkTimeOptimizationViaAPI()
		linktimeoptimization "Fast"
		prepare()
		test.isequal("clang", clang.gettoolname(cfg, "cc"))
		test.isequal("clang++", clang.gettoolname(cfg, "cxx"))
		test.isequal("llvm-ar", clang.gettoolname(cfg, "ar"))
		test.isequal("windres", clang.gettoolname(cfg, "rc"))
	end

	function suite.tools_onMacOSWithLinkTimeOptimization()
		system "MacOSX"
		linktimeoptimization "On"
		prepare()
		test.isequal("ar", clang.gettoolname(cfg, "ar"))
	end

	function suite.tools_forVersion_onMacOSWithLinkTimeOptimization()
		system "MacOSX"
		toolset "clang-16"
		linktimeoptimization "On"
		prepare()
		test.isequal("clang-16", clang.gettoolname(cfg, "cc"))
		test.isequal("clang++-16", clang.gettoolname(cfg, "cxx"))
		test.isequal("ar", clang.gettoolname(cfg, "ar"))
		test.isequal("windres-16", clang.gettoolname(cfg, "rc"))
	end

	function suite.tools_forVersion()
		toolset "clang-16"
		prepare()
		test.isequal("clang-16", clang.gettoolname(cfg, "cc"))
		test.isequal("clang++-16", clang.gettoolname(cfg, "cxx"))
		test.isequal("ar-16", clang.gettoolname(cfg, "ar"))
		test.isequal("windres-16", clang.gettoolname(cfg, "rc"))
	end

	function suite.tools_forVersion_onWindows()
		system "Windows"
		toolset "clang-16"
		prepare()
		test.isequal("llvm-ar-16", clang.gettoolname(cfg, "ar"))
	end

	function suite.tools_forVersion_onLinkTimeOptimizationViaAPI()
		toolset "clang-16"
		linktimeoptimization "On"
		prepare()
		test.isequal("clang-16", clang.gettoolname(cfg, "cc"))
		test.isequal("clang++-16", clang.gettoolname(cfg, "cxx"))
		test.isequal("llvm-ar-16", clang.gettoolname(cfg, "ar"))
		test.isequal("windres-16", clang.gettoolname(cfg, "rc"))
	end

	function suite.tools_forVersion_onFastLinkTimeOptimizationViaAPI()
		toolset "clang-16"
		linktimeoptimization "Fast"
		prepare()
		test.isequal("clang-16", clang.gettoolname(cfg, "cc"))
		test.isequal("clang++-16", clang.gettoolname(cfg, "cxx"))
		test.isequal("llvm-ar-16", clang.gettoolname(cfg, "ar"))
		test.isequal("windres-16", clang.gettoolname(cfg, "rc"))
	end

--
-- Check Mac OS X deployment target flags
--

	function suite.cflags_macosx_systemversion()
		system "MacOSX"
		systemversion "10.9"
		prepare()
		test.contains({ "-mmacosx-version-min=10.9" }, clang.getcflags(cfg))
	end

	function suite.cxxflags_macosx_systemversion()
		system "MacOSX"
		systemversion "10.9"
		prepare()
		test.contains({ "-mmacosx-version-min=10.9" }, clang.getcxxflags(cfg))
	end

	function suite.cxxflags_macosx_systemversion_unspecified()
		system "MacOSX"
		prepare()
		test.excludes({ "-mmacosx-version-min=10.9" }, clang.getcxxflags(cfg))
	end

--
-- Check iOS deployment target flags
--

	function suite.cflags_ios_systemversion()
		system "iOS"
		systemversion "12.1"
		prepare()
		test.contains({ "-miphoneos-version-min=12.1" }, clang.getcflags(cfg))
	end

	function suite.cxxflags_ios_systemversion()
		system "iOS"
		systemversion "5.0"
		prepare()
		test.contains({ "-miphoneos-version-min=5.0" }, clang.getcxxflags(cfg))
	end

--
-- Check tvOS deployment target flags
--

function suite.cflags_tvos_systemversion()
	system "tvOS"
	systemversion "12.1"
	prepare()
	test.contains({ "-mappletvos-version-min=12.1" }, clang.getcflags(cfg))
end

function suite.cxxflags_tvos_systemversion()
	system "tvOS"
	systemversion "5.0"
	prepare()
	test.contains({ "-mappletvos-version-min=5.0" }, clang.getcxxflags(cfg))
end

--
-- Check handling of openmp.
--

	function suite.cflags_onOpenmpOn()
		openmp "On"
		prepare()
		test.contains("-fopenmp", clang.getcflags(cfg))
	end

	function suite.cflags_onOpenmpOff()
		openmp "Off"
		prepare()
		test.excludes("-fopenmp", clang.getcflags(cfg))
	end

	function suite.cflags_onAVX512()
		vectorextensions "AVX512"
		prepare()
		test.contains({ "-mavx512f" }, clang.getcflags(cfg))
	end

	function suite.cxxflags_onOpenmpOn()
		openmp "On"
		prepare()
		test.contains("-fopenmp", clang.getcxxflags(cfg))
	end

	function suite.cxxflags_onOpenmpOff()
		openmp "Off"
		prepare()
		test.excludes("-fopenmp", clang.getcxxflags(cfg))
	end

	function suite.ldflags_onOpenmpOn()
		openmp "On"
		prepare()
		test.contains("-fopenmp", clang.getldflags(cfg))
	end

	function suite.ldflags_onOpenmpOff()
		openmp "Off"
		prepare()
		test.excludes("-fopenmp", clang.getldflags(cfg))
	end

--
-- Check handling of linker flag.
--

	function suite.ldflags_linker_lld()
		linker "LLD"
		prepare()
		test.contains("-fuse-ld=lld", clang.getldflags(cfg))
	end

--
-- Check handling of link time optimization flag.
--

	function suite.cflags_onLinkTimeOptimizationViaAPI()
		linktimeoptimization "On"
		prepare()
		test.contains("-flto", clang.getcflags(cfg))
	end

	function suite.cflags_onFastLinkTimeOptimizationViaAPI()
		linktimeoptimization "Fast"
		prepare()
		test.contains("-flto=thin", clang.getcflags(cfg))
	end

	function suite.ldflags_onLinkTimeOptimizationViaAPI()
		linktimeoptimization "On"
		prepare()
		test.contains("-flto", clang.getldflags(cfg))
	end

	function suite.ldflags_onFastLinkTimeOptimizationViaAPI()
		linktimeoptimization "Fast"
		prepare()
		test.contains("-flto=thin", clang.getldflags(cfg))
	end

--
-- Check the translation of CXXFLAGS.
--

	function suite.onSanitizeAddress()
		sanitize { "Address" }
		prepare()
		test.contains({ "-fsanitize=address" }, clang.getcxxflags(cfg))
		test.contains({ "-fsanitize=address" }, clang.getcflags(cfg))
		test.contains({ "-fsanitize=address" }, clang.getldflags(cfg))
	end

	function suite.cxxflags_onSanitizeFuzzer()
		sanitize { "Fuzzer" }
		prepare()
		test.contains({ "-fsanitize=fuzzer" }, clang.getcxxflags(cfg))
		test.contains({ "-fsanitize=fuzzer" }, clang.getcflags(cfg))
		test.contains({ "-fsanitize=fuzzer" }, clang.getldflags(cfg))
	end

	function suite.cxxflags_onSanitizeThread()
		sanitize { "Thread" }
		prepare()
		test.contains({ "-fsanitize=thread" }, clang.getcxxflags(cfg))
		test.contains({ "-fsanitize=thread" }, clang.getcflags(cfg))
		test.contains({ "-fsanitize=thread" }, clang.getldflags(cfg))
	end

	-- UBSan
	function suite.cxxflags_onSanitizeUndefined()
		sanitize { "UndefinedBehavior" }
		prepare()
		test.contains({ "-fsanitize=undefined" }, clang.getcxxflags(cfg))
		test.contains({ "-fsanitize=undefined" }, clang.getcflags(cfg))
		test.contains({ "-fsanitize=undefined" }, clang.getldflags(cfg))
	end

--
-- Test the optimization flags.
--
	function suite.onOptimizeDebug()
		optimize "Debug"
		prepare()
		test.contains("-Og", clang.getcflags(cfg))
		test.contains("-Og", clang.getcxxflags(cfg))
	end

	function suite.onOptimizeSize()
		optimize "Size"
		prepare()
		test.contains("-Os", clang.getcflags(cfg))
		test.contains("-Os", clang.getcxxflags(cfg))
	end

	function suite.onOptimizeSpeed()
		optimize "Speed"
		prepare()
		test.contains("-O3", clang.getcflags(cfg))
		test.contains("-O3", clang.getcxxflags(cfg))
	end

	function suite.onOptimizeOff()
		optimize "Off"
		prepare()
		test.contains("-O0", clang.getcflags(cfg))
		test.contains("-O0", clang.getcxxflags(cfg))
	end

	function suite.onOptimizeOn()
		optimize "On"
		prepare()
		test.contains("-O2", clang.getcflags(cfg))
		test.contains("-O2", clang.getcxxflags(cfg))
	end

	function suite.onOptimizeFull()
		optimize "Full"
		prepare()
		test.contains("-O3", clang.getcflags(cfg))
		test.contains("-O3", clang.getcxxflags(cfg))
	end

--
-- Check handling of floating point modifiers.
--

	function suite.cflags_onFloatingPointFast()
		floatingpoint "Fast"
		prepare()
		test.contains({ "-ffast-math" }, clang.getcflags(cfg))
	end

	function suite.cflags_onFloatingPointStrict()
		floatingpoint "Strict"
		prepare()
		test.contains({ "-ffp-model=strict" }, clang.getcflags(cfg))
	end

	function suite.cflags_onFloatingPointPrecise()
		floatingpoint "Precise"
		prepare()
		test.contains({ "-ffp-model=precise" }, clang.getcflags(cfg))
	end

--
-- Check handling of external warnings.
--

	function suite.cflags_onNoExternalWarnings()
		externalwarnings "Off"
		prepare()
		test.excludes({ "-Wsystem-headers" }, clang.getcflags(cfg))
	end

	function suite.cflags_onHighExternalWarnings()
		externalwarnings "High"
		prepare()
		test.contains({ "-Wsystem-headers" }, clang.getcflags(cfg))
	end

--
-- Test profiling flag
--

	function suite.flags_onProfileOff()
		profile "Off"

		prepare()
		test.excludes({ "-pg" }, clang.getcflags(cfg))
		test.excludes({ "-pg" }, clang.getcxxflags(cfg))
		test.excludes({ "-pg" }, clang.getldflags(cfg))
	end

	function suite.flags_onProfileOn()
		profile "On"

		prepare()
		test.contains({ "-pg" }, clang.getcflags(cfg))
		test.contains({ "-pg" }, clang.getcxxflags(cfg))
		test.contains({ "-pg" }, clang.getldflags(cfg))
	end

--
-- Make sure system or architecture flags are added properly.
--

	function suite.cflags_onX86()
		architecture "x86"
		prepare()
		test.contains({ "-m32" }, clang.getcflags(cfg))
	end

	function suite.ldflags_onX86()
		architecture "x86"
		prepare()
		test.contains({ "-m32" }, clang.getldflags(cfg))
	end

	function suite.cflags_onX86_64()
		architecture "x86_64"
		prepare()
		test.contains({ "-m64" }, clang.getcflags(cfg))
	end

	function suite.ldflags_onX86_64()
		architecture "x86_64"
		prepare()
		test.contains({ "-m64" }, clang.getldflags(cfg))
	end

	function suite.cflags_macosx_onX86()
		system "macosx"
		architecture "x86"
		prepare()
		test.excludes({ "-m32" }, clang.getcflags(cfg))
		test.contains({ "-arch i386" }, clang.getcflags(cfg))
	end

	function suite.ldflags_macosx_onX86()
		system "macosx"
		architecture "x86"
		prepare()
		test.excludes({ "-m32" }, clang.getldflags(cfg))
		test.contains({ "-arch i386" }, clang.getldflags(cfg))
	end

	function suite.cflags_macosx_onX86_64()
		system "macosx"
		architecture "x86_64"
		prepare()
		test.excludes({ "-m64" }, clang.getcflags(cfg))
		test.contains({ "-arch x86_64" }, clang.getcflags(cfg))
	end

	function suite.ldflags_macosx_onX86_64()
		system "macosx"
		architecture "x86_64"
		prepare()
		test.excludes({ "-m64" }, clang.getldflags(cfg))
		test.contains({ "-arch x86_64" }, clang.getldflags(cfg))
	end

	function suite.cflags_macosx_onAARCH64()
		system "macosx"
		architecture "AARCH64"
		prepare()
		test.contains({ "-arch arm64" }, clang.getcflags(cfg))
	end

	function suite.cflags_macosx_onarm64()
		system "macosx"
		architecture "arm64"
		prepare()
		test.contains({ "-arch arm64" }, clang.getcflags(cfg))
	end

	function suite.ldflags_macosx_onAARCH64()
		system "macosx"
		architecture "AARCH64"
		prepare()
		test.contains({ "-arch arm64" }, clang.getldflags(cfg))
	end

	function suite.ldflags_macosx_onarm64()
		system "macosx"
		architecture "arm64"
		prepare()
		test.contains({ "-arch arm64" }, clang.getldflags(cfg))
	end

--
-- Make sure unicode support is handled properly.
--

	function suite.cflags_onUnicode_Windows()
		system "Windows"
		characterset "Unicode"
		prepare()
		test.contains({ "-D_UNICODE", "-DUNICODE", "-municode" }, clang.getcflags(cfg))
	end

	function suite.cxxflags_onUnicode_Windows()
		system "Windows"
		characterset "Unicode"
		prepare()
		test.contains({ "-D_UNICODE", "-DUNICODE", "-municode" }, clang.getcxxflags(cfg))
	end

	function suite.ldflags_onWindowsSharedLib()
		system "Windows"
		kind "SharedLib"
		prepare()
		test.contains({ "-shared", '-Xlinker /IMPLIB:"bin/Debug/MyProject.lib"' }, clang.getldflags(cfg))
	end

	function suite.ldflags_onWindowsSharedLibWithoutImportLib()
		system "Windows"
		kind "SharedLib"
		useimportlib "Off"
		prepare()
		test.contains({ "-shared", "-Xlinker /NOIMPLIB" }, clang.getldflags(cfg))
	end

	function suite.ldflags_onBSDSharedLib()
		system "bsd"
		kind "SharedLib"
		prepare()
		test.contains({ "-shared", "-Wl,-soname=libMyProject.so" }, clang.getldflags(cfg))
	end


--
-- Check handling of Run-Time Library flags.
--

	function suite.cflags_onWindowsStaticRuntime()
		system "Windows"
		staticruntime "On"
		symbols "On"
		prepare()
		test.contains({ "-fms-runtime-lib=static_dbg" }, clang.getcflags(cfg))
	end

	function suite.cflags_onWindowsDynamicRuntime()
		system "Windows"
		staticruntime "Off"
		runtime "Debug"
		prepare()
		test.contains({ "-fms-runtime-lib=dll_dbg" }, clang.getcflags(cfg))
	end

	function suite.cflags_onWindowsStaticRuntimeRelease()
		system "Windows"
		staticruntime "On"
		runtime "Release"
		prepare()
		test.contains({ "-fms-runtime-lib=static" }, clang.getcflags(cfg))
	end

	function suite.cflags_onWindowsDynamicRuntimeRelease()
		system "Windows"
		staticruntime "Off"
		runtime "Release"
		prepare()
		test.contains({ "-fms-runtime-lib=dll" }, clang.getcflags(cfg))
	end

	function suite.ldflags_onWindowsStaticRuntime()
		system "Windows"
		staticruntime "On"
		symbols "On"
		prepare()
		test.contains({ "-Xlinker /NODEFAULTLIB:libcmt -fms-runtime-lib=static_dbg" }, clang.getldflags(cfg))
	end

	function suite.ldflags_onWindowsDynamicRuntime()
		system "Windows"
		staticruntime "Off"
		runtime "Debug"
		prepare()
		test.contains({ "-Xlinker /NODEFAULTLIB:libcmt -fms-runtime-lib=dll_dbg" }, clang.getldflags(cfg))
	end

	function suite.ldflags_onWindowsDynamicRuntimeRelease()
		system "Windows"
		staticruntime "Off"
		runtime "Release"
		prepare()
		test.contains({ "-Xlinker /NODEFAULTLIB:libcmt -fms-runtime-lib=dll" }, clang.getldflags(cfg))
	end

	function suite.cflags_onNonWindowsRuntime()
		system "Linux"
		staticruntime "On"
		prepare()
		test.excludes({ "-fms-runtime-lib=static_dbg" }, clang.getcflags(cfg))
	end

	function suite.ldflags_onNonWindowsRuntime()
		system "Linux"
		staticruntime "On"
		prepare()
		test.excludes({ "-fms-runtime-lib=static_dbg" }, clang.getldflags(cfg))
	end

	function suite.ldflags_onUnicode_Windows()
		system "Windows"
		characterset "Unicode"
		prepare()
		test.contains({ "-municode" }, clang.getldflags(cfg))
	end

	function suite.cflags_onUnicode_NonWindows()
		system "Linux"
		characterset "Unicode"
		prepare()
		test.excludes({ "-D_UNICODE", "-DUNICODE", "-municode" }, clang.getcflags(cfg))
	end

	function suite.cxxflags_onUnicode_NonWindows()
		system "Linux"
		characterset "Unicode"
		prepare()
		test.excludes({ "-D_UNICODE", "-DUNICODE", "-municode" }, clang.getcxxflags(cfg))
	end

	function suite.ldflags_onUnicode_NonWindows()
		system "Linux"
		characterset "Unicode"
		prepare()
		test.excludes({ "-municode" }, clang.getldflags(cfg))
	end

	function suite.inlinesVisibilityHidden_onlyInCxxFlags()
		inlinesvisibility "Hidden"
		prepare()
		test.excludes({ "-fvisibility-inlines-hidden" }, clang.getcflags(cfg))
		test.contains({ "-fvisibility-inlines-hidden" }, clang.getcxxflags(cfg))
	end


--
-- Check ASLR hardening flags for Clang.
--

	-- On emits -fPIE for executables in C and C++.
	function suite.cflags_onHardenAslrOn_consoleApp()
		kind "ConsoleApp"
		hardenaslr "On"
		prepare()
		test.contains({ "-fPIE" }, clang.getcflags(cfg))
		test.contains({ "-fPIE" }, clang.getcxxflags(cfg))
	end

	-- Off emits -fno-PIE for executables in C and C++.
	function suite.cflags_onHardenAslrOff_consoleApp()
		kind "ConsoleApp"
		hardenaslr "Off"
		prepare()
		test.contains({ "-fno-PIE" }, clang.getcflags(cfg))
		test.contains({ "-fno-PIE" }, clang.getcxxflags(cfg))
	end

	-- Default emits no PIE flags for executables in C or C++.
	function suite.cflags_onHardenAslrDefault_consoleApp()
		kind "ConsoleApp"
		hardenaslr "Default"
		prepare()
		test.excludes({ "-fPIE", "-fno-PIE" }, clang.getcflags(cfg))
		test.excludes({ "-fPIE", "-fno-PIE" }, clang.getcxxflags(cfg))
	end

	-- On emits -fPIC for static libraries.
	function suite.cflags_onHardenAslrOn_staticLib()
		kind "StaticLib"
		hardenaslr "On"
		prepare()
		test.contains({ "-fPIC" }, clang.getcflags(cfg))
		test.contains({ "-fPIC" }, clang.getcxxflags(cfg))
	end

	-- On emits -fPIE and -pie linker flags for executables.
	function suite.ldflags_onHardenAslrOn_consoleApp()
		kind "ConsoleApp"
		hardenaslr "On"
		prepare()
		test.contains({ "-fPIE", "-pie" }, clang.getldflags(cfg))
	end

	-- Off emits -fno-PIE and -no-pie linker flags for executables.
	function suite.ldflags_onHardenAslrOff_consoleApp()
		kind "ConsoleApp"
		hardenaslr "Off"
		prepare()
		test.contains({ "-fno-PIE", "-no-pie" }, clang.getldflags(cfg))
	end

	-- Default emits no PIE linker flags for executables.
	function suite.ldflags_onHardenAslrDefault_consoleApp()
		kind "ConsoleApp"
		hardenaslr "Default"
		prepare()
		test.excludes({ "-pie", "-no-pie", "-fPIE", "-fno-PIE" }, clang.getldflags(cfg))
	end

	-- On links with matching PIE code generation.
	function suite.ldflags_onHardenAslrOn_withPicOn_consoleApp()
		kind "ConsoleApp"
		hardenaslr "On"
		pic "On"
		prepare()
		test.contains({ "-fPIE", "-pie" }, clang.getldflags(cfg))
		test.excludes({ "-fPIC" }, clang.getldflags(cfg))
	end

	-- Off with pic On emits -fPIC and -no-pie linker flags for executables.
	function suite.ldflags_onHardenAslrOff_withPicOn_consoleApp()
		kind "ConsoleApp"
		hardenaslr "Off"
		pic "On"
		prepare()
		test.contains({ "-fPIC", "-no-pie" }, clang.getldflags(cfg))
		test.excludes({ "-fno-PIE" }, clang.getldflags(cfg))
	end

	-- On emits no PIE linker flags for static libraries.
	function suite.ldflags_onHardenAslrOn_staticLib()
		kind "StaticLib"
		hardenaslr "On"
		prepare()
		test.excludes({ "-pie", "-no-pie" }, clang.getldflags(cfg))
	end

	-- Shared libraries link as PIC without PIE flags.
	function suite.ldflags_onHardenAslrOn_sharedLib()
		kind "SharedLib"
		hardenaslr "On"
		prepare()
		test.excludes({ "-pie", "-no-pie" }, clang.getldflags(cfg))
		test.contains({ "-fPIC", "-shared" }, clang.getldflags(cfg))
	end

	-- Raises an error when ASLR is On and PIC is explicitly Off on Linux.
	function suite.raisesError_onHardenAslrOn_withPicOff()
		kind "ConsoleApp"
		hardenaslr "On"
		pic "Off"
		prepare()
		local ok, err = pcall(function ()
			clang.getcflags(cfg)
		end)
		test.isfalse(ok)
	end

	-- Unsupported target systems reject active ASLR requests.
	function suite.cflags_onHardenAslrOn_nonLinux()
		system "MacOSX"
		kind "ConsoleApp"
		hardenaslr "On"
		prepare()
		for _, getflags in ipairs({ clang.getcflags, clang.getcxxflags, clang.getldflags }) do
			local ok, err = pcall(getflags, cfg)
			test.isfalse(ok)
			test.istrue(err:find("hardenaslr", 1, true) ~= nil)
		end
	end

	-- Clang cannot map a Windows MSVC ASLR request.
	function suite.hardenAslr_rejectsMsvcTarget()
		system "Windows"
		toolset "msc"
		hardenaslr "On"
		prepare()
		local ok, err = pcall(clang.getcflags, cfg)
		test.isfalse(ok)
		test.istrue(err:find("hardenaslr", 1, true) ~= nil)
	end

	local function checkWindowsAslr(projectKind, imageArchitecture)
		system "Windows"
		architecture(imageArchitecture)
		toolset "clang"
		kind(projectKind)
		filter "configurations:Debug"
			hardenaslr "On"
		filter "configurations:Release"
			hardenaslr "Off"
		prepare()
		local release = p.project.getconfig(cfg.project, "Release")
		test.contains({ "-Xlinker /DYNAMICBASE" }, clang.getldflags(cfg))
		test.contains({ "-Xlinker /DYNAMICBASE:NO" }, clang.getldflags(release))
		for _, imagecfg in ipairs({ cfg, release }) do
			test.excludes({ "-fPIC", "-fPIE", "-fno-PIE", "-pie", "-no-pie", "-Wl,--dynamicbase" }, clang.getldflags(imagecfg))
			test.excludes({ "-fPIC", "-fPIE", "-fno-PIE", "-Xlinker /DYNAMICBASE", "-Xlinker /DYNAMICBASE:NO" }, clang.getcflags(imagecfg))
			test.excludes({ "-fPIC", "-fPIE", "-fno-PIE", "-Xlinker /DYNAMICBASE", "-Xlinker /DYNAMICBASE:NO" }, clang.getcxxflags(imagecfg))
		end
	end

	-- Windows executables use the MSVC linker dialect.
	function suite.hardenAslr_windowsExecutableOptions()
		checkWindowsAslr("ConsoleApp", "x86")
	end

	-- Windows DLLs use the MSVC linker dialect.
	function suite.hardenAslr_windowsSharedLibraryOptions()
		checkWindowsAslr("SharedLib", "x86_64")
	end

	-- Windows archives and defaults add no ASLR overrides.
	function suite.hardenAslr_windowsArchivesAndDefaults()
		system "Windows"
		toolset "clang"
		configurations { "On", "Off", "Default", "Unset" }
		filter "configurations:On or Off"
			kind "StaticLib"
		filter "configurations:On"
			hardenaslr "On"
		filter "configurations:Off"
			hardenaslr "Off"
		filter "configurations:Default"
			hardenaslr "Default"
		local neutral = test.getconfig(prj, "Unset")
		for _, name in ipairs({ "On", "Off", "Default", "Unset" }) do
			local imagecfg = p.project.getconfig(neutral.project, name)
			test.excludes({ "-Xlinker /DYNAMICBASE", "-Xlinker /DYNAMICBASE:NO", "-fPIC", "-fPIE", "-fno-PIE", "-pie", "-no-pie" }, clang.getldflags(imagecfg))
			test.excludes({ "-fPIC", "-fPIE", "-fno-PIE" }, clang.getcflags(imagecfg))
			test.excludes({ "-fPIC", "-fPIE", "-fno-PIE" }, clang.getcxxflags(imagecfg))
		end
	end

	-- Windows ARM rejects ASLR Off.
	function suite.hardenAslr_windowsArmOffRejected()
		system "Windows"
		toolset "clang"
		architecture "ARM64"
		hardenaslr "Off"
		prepare()
		local ok, err = pcall(clang.getldflags, cfg)
		test.isfalse(ok)
		test.istrue(err:find("ARM", 1, true) ~= nil)
	end

	local function aslrCodeFlags(flags)
		local selected = {}
		for _, flag in ipairs(flags) do
			if flag == "-fPIC" or flag == "-fPIE" or flag == "-fno-PIE" then
				table.insert(selected, flag)
			end
		end
		return selected
	end

	-- PIE code generation appears once in each phase.
	function suite.hardenAslr_executableCodeModelIsUnique()
		hardenaslr "On"
		pic "On"
		prepare()
		test.isequal({ "-fPIE" }, aslrCodeFlags(clang.getcflags(cfg)))
		test.isequal({ "-fPIE" }, aslrCodeFlags(clang.getcxxflags(cfg)))
		test.isequal({ "-fPIE" }, aslrCodeFlags(clang.getldflags(cfg)))
	end

	-- Shared library PIC appears once in each phase.
	function suite.hardenAslr_sharedCodeModelIsUnique()
		kind "SharedLib"
		hardenaslr "On"
		prepare()
		test.isequal({ "-fPIC" }, aslrCodeFlags(clang.getcflags(cfg)))
		test.isequal({ "-fPIC" }, aslrCodeFlags(clang.getcxxflags(cfg)))
		test.isequal({ "-fPIC" }, aslrCodeFlags(clang.getldflags(cfg)))
	end

	-- ASLR Off preserves one explicit PIC choice.
	function suite.hardenAslr_offPicCodeModelIsUnique()
		hardenaslr "Off"
		pic "On"
		prepare()
		test.isequal({ "-fPIC" }, aslrCodeFlags(clang.getcflags(cfg)))
		test.isequal({ "-fPIC" }, aslrCodeFlags(clang.getcxxflags(cfg)))
		test.isequal({ "-fPIC" }, aslrCodeFlags(clang.getldflags(cfg)))
	end
