--
-- tests/base/test_validation.lua
-- Verify the project information sanity checking.
-- Copyright (c) 2013-20124 Jess Perkins and the Premake project
--

	local suite = test.declare("premake_validation")

	local p = premake


--
-- Setup
--

	local function validate()
		return pcall(function() p.container.validate(p.api.rootContainer()) end)
	end


--
-- Validate should pass if the minimum requirements are met.
--

	function suite.passes_onSane()
		workspace("MyWorkspace")
			configurations { "Debug", "Release" }
		project "MyProject"
			kind "ConsoleApp"
			language "C++"
		test.istrue(validate())
	end


--
-- Fail if no configurations are present on the workspace.
--

	function suite.fails_onNoWorkspaceConfigs()
		workspace "MyWorkspace"
		project "MyProject"
			kind "ConsoleApp"
			language "C++"
		test.isfalse(validate())
	end


--
-- Fail on duplicate project UUIDs.
--

	function suite.fails_onDuplicateProjectIDs()
		workspace "MyWorkspace"
			configurations { "Debug", "Release" }
			kind "ConsoleApp"
			language "C++"
		project "MyProject1"
			uuid "D4110D7D-FB18-4A1C-A75B-CA432F4FE770"
		project "MyProject2"
			uuid "D4110D7D-FB18-4A1C-A75B-CA432F4FE770"
		test.isfalse(validate())
	end


--
-- Fail if no kind is set on the configuration.
--

	function suite.fails_onNoConfigKind()
		workspace "MyWorkspace"
			configurations { "Debug", "Release" }
		project "MyProject"
			language "C++"
		test.isfalse(validate())
	end


--
-- Warn if a configuration value is set in the wrong scope.
--

	function suite.warns_onWorkspaceStringField_inConfig()
		workspace "MyWorkspace"
			configurations { "Debug", "Release" }
		filter "Debug"
			startproject "MyProject"
		project "MyProject"
			kind "ConsoleApp"
			language "C++"
		validate()
		test.stderr("'startproject' on config")
	end

	function suite.warns_onProjectStringField_inConfig()
		workspace "MyWorkspace"
			configurations { "Debug", "Release" }
		project "MyProject"
			kind "ConsoleApp"
			language "C++"
		filter "Debug"
			location "MyProject"
		validate()
		test.stderr("'location' on config")
	end

	function suite.warns_onProjectListField_inConfig()
		workspace "MyWorkspace"
			configurations { "Debug", "Release" }
		project "MyProject"
			kind "ConsoleApp"
			language "C++"
		filter "Debug"
			configurations "Deployment"
		validate()
		test.stderr("'configurations' on config")
	end


--
-- If a rule is specified for inclusion, it must have been defined.
--

	function suite.fails_onNoSuchRule()
		workspace "MyWorkspace"
			configurations { "Debug", "Release" }
		project "MyProject"
			rules { "NoSuchRule" }
		test.isfalse(validate())
	end


--
-- Validate ASLR hardening configuration sanity.
--

	local function aslrProject(action, target, compiler)
		p.action.set(action)
		local wks, prj = test.createWorkspace()
		system(target)
		toolset(compiler)
		architecture "x86_64"
		return prj
	end

	local function validateAslr(prj)
		return pcall(function()
			local cfg = test.getconfig(prj, "Debug")
			p.project.validate(cfg.project)
		end)
	end

	local function checkAslrError(prj, message)
		local ok, err = validateAslr(prj)
		test.isfalse(ok)
		test.isequal(message, err:find(message, 1, true) and message or err)
	end

	-- Fail if ASLR is On and PIC is explicitly Off on Linux.
	function suite.fails_onHardenAslrOn_withPicOff_onLinux()
		local prj = aslrProject("gmake", "Linux", "gcc")
		hardenaslr "On"
		pic "Off"
		checkAslrError(prj, "pic Off")
	end

	-- Fail if ASLR is Off on ARM architecture on Windows.
	function suite.fails_onHardenAslrOff_onArm_onWindows()
		local prj = aslrProject("vs2022", "Windows", "msc")
		architecture "ARM64"
		hardenaslr "Off"
		checkAslrError(prj, "ARM")
	end

	-- ASLR On permits the default Linux PIC setting.
	function suite.passes_onHardenAslrOn_onLinux()
		local prj = aslrProject("gmake", "Linux", "gcc")
		hardenaslr "On"
		test.istrue(validateAslr(prj))
	end

	-- Pass when ASLR is Off on x86_64 architecture on Windows.
	function suite.passes_onHardenAslrOff_onX86_onWindows()
		local prj = aslrProject("vs2022", "Windows", "msc")
		hardenaslr "Off"
		test.istrue(validateAslr(prj))
	end


	-- Active ASLR rejects unsupported target systems.
	function suite.hardenAslr_rejectsUnsupportedSystem()
		local prj = aslrProject("gmake", "MacOSX", "clang")
		hardenaslr "On"
		checkAslrError(prj, "hardenaslr")
	end

	-- Active ASLR rejects unsupported exporters.
	function suite.hardenAslr_rejectsUnsupportedAction()
		local prj = aslrProject("xcode4", "Linux", "gcc")
		hardenaslr "Off"
		checkAslrError(prj, "hardenaslr")
	end

	-- Active ASLR rejects unsupported compilers.
	function suite.hardenAslr_rejectsUnsupportedToolset()
		local prj = aslrProject("gmake", "Linux", "emcc")
		hardenaslr "On"
		checkAslrError(prj, "hardenaslr")
	end

	-- Native Windows Visual Studio rejects GCC.
	function suite.hardenAslr_rejectsWindowsGccVisualStudio()
		local prj = aslrProject("vs2022", "Windows", "gcc")
		hardenaslr "On"
		checkAslrError(prj, "hardenaslr")
	end

	-- VS2005 accepts the ASLR setting.
	function suite.hardenAslr_acceptsVisualStudio2005()
		local prj = aslrProject("vs2005", "Windows", "msc")
		hardenaslr "On"
		test.istrue(validateAslr(prj))
	end

	-- CodeLite accepts Windows GCC ASLR.
	function suite.hardenAslr_acceptsCodeLiteWindowsGcc()
		local prj = aslrProject("codelite", "Windows", "gcc")
		hardenaslr "On"
		test.istrue(validateAslr(prj))
	end

	-- CodeLite accepts Linux Clang ASLR.
	function suite.hardenAslr_acceptsCodeLiteLinuxClang()
		local prj = aslrProject("codelite", "Linux", "clang")
		hardenaslr "On"
		test.istrue(validateAslr(prj))
	end

	-- Ninja accepts Windows MSVC ASLR.
	function suite.hardenAslr_acceptsNinjaWindowsMsvc()
		local prj = aslrProject("ninja", "Windows", "msc")
		hardenaslr "On"
		test.istrue(validateAslr(prj))
	end

	-- CodeLite accepts Windows MSVC ASLR.
	function suite.hardenAslr_acceptsCodeLiteWindowsMsvc()
		local prj = aslrProject("codelite", "Windows", "msc")
		hardenaslr "Off"
		test.istrue(validateAslr(prj))
	end

	-- Native Visual Studio accepts its ClangCL toolset.
	function suite.hardenAslr_acceptsVisualStudioClangCl()
		local prj = aslrProject("vs2019", "Windows", "clang")
		hardenaslr "On"
		test.istrue(validateAslr(prj))
	end

	-- Windows ASLR rejects unsupported architectures.
	function suite.hardenAslr_rejectsUnsupportedWindowsArchitecture()
		local prj = aslrProject("vs2022", "Windows", "msc")
		architecture "PPC"
		hardenaslr "On"
		checkAslrError(prj, "hardenaslr")
	end

	-- Linux shared libraries have no ASLR Off mapping.
	function suite.hardenAslr_rejectsSharedLibraryOff()
		local prj = aslrProject("gmake", "Linux", "gcc")
		kind "SharedLib"
		hardenaslr "Off"
		checkAslrError(prj, "hardenaslr")
	end

	-- Linux static libraries have no ASLR Off mapping.
	function suite.hardenAslr_rejectsStaticLibraryOff()
		local prj = aslrProject("gmake", "Linux", "gcc")
		kind "StaticLib"
		hardenaslr "Off"
		checkAslrError(prj, "hardenaslr")
	end

	-- ASLR cannot change for an individual file.
	function suite.hardenAslr_rejectsFileOverride()
		local prj = aslrProject("gmake", "Linux", "gcc")
		files { "main.cpp" }
		hardenaslr "On"
		filter "files:main.cpp"
			hardenaslr "Off"
		checkAslrError(prj, "hardenaslr")
	end

	-- ASLR requires a project configuration setting.
	function suite.hardenAslr_rejectsFileOnlySetting()
		local prj = aslrProject("ninja", "Linux", "clang")
		files { "main.cpp" }
		filter "files:main.cpp"
			hardenaslr "On"
		checkAslrError(prj, "hardenaslr")
	end

	-- Inherited ASLR On rejects file PIC Off.
	function suite.hardenAslr_rejectsFilePicConflict()
		local prj = aslrProject("gmake", "Linux", "gcc")
		files { "main.cpp" }
		hardenaslr "On"
		filter "files:main.cpp"
			pic "Off"
		checkAslrError(prj, "hardenaslr")
	end

	-- Default remains neutral on unsupported targets.
	function suite.hardenAslr_defaultAllowsUnsupportedTarget()
		local prj = aslrProject("codelite", "MacOSX", "clang")
		hardenaslr "Default"
		test.istrue(validateAslr(prj))
	end

	-- File build options permit inherited ASLR.
	function suite.hardenAslr_preservesFileMetadata()
		local prj = aslrProject("ninja", "Linux", "clang")
		files { "main.cpp" }
		hardenaslr "On"
		filter "files:main.cpp"
			buildoptions { "-fno-exceptions" }
		test.istrue(validateAslr(prj))
	end

	-- ASLR rejects managed projects.
	function suite.hardenAslr_rejectsUnsupportedLanguage()
		local prj = aslrProject("vs2022", "Windows", "msc")
		language "C#"
		hardenaslr "On"
		checkAslrError(prj, "hardenaslr")
	end

	-- Utility projects have no ASLR mapping.
	function suite.hardenAslr_rejectsUtilityRequest()
		local prj = aslrProject("gmake", "Linux", "gcc")
		kind "Utility"
		hardenaslr "On"
		checkAslrError(prj, "hardenaslr")
	end

	-- ASLR Off rejects a different file code model.
	function suite.hardenAslr_rejectsFilePicModelChange()
		local prj = aslrProject("gmake", "Linux", "gcc")
		files { "main.cpp" }
		hardenaslr "Off"
		filter "files:main.cpp"
			pic "On"
		checkAslrError(prj, "hardenaslr")
	end

	-- File PIC Off preserves the unset project code model.
	function suite.hardenAslr_acceptsFilePicOff_withProjectPicUnset()
		local prj = aslrProject("gmake", "Linux", "gcc")
		files { "main.cpp" }
		hardenaslr "Off"
		filter "files:main.cpp"
			pic "Off"
		local ok, err = validateAslr(prj)
		test.isequal("", err or "")
		test.istrue(ok)
	end

	-- Workspace ASLR On conflicts with project PIC Off.
	function suite.hardenAslr_inheritsWorkspaceConflict()
		local prj = aslrProject("gmake", "Linux", "gcc")
		workspace "MyWorkspace"
			hardenaslr "On"
		project "MyProject"
			pic "Off"
		checkAslrError(prj, "pic Off")
	end

	-- Configuration ASLR values produce separate linker flags.
	function suite.hardenAslr_configurationValuesStaySeparate()
		local prj = aslrProject("ninja", "Linux", "clang")
		filter "configurations:Debug"
			hardenaslr "On"
		filter "configurations:Release"
			hardenaslr "Off"
		local debug = test.getconfig(prj, "Debug")
		local release = p.project.getconfig(debug.project, "Release")
		p.project.validate(debug.project)
		test.contains({ "-fPIE", "-pie" }, p.tools.clang.getldflags(debug))
		test.excludes({ "-fno-PIE", "-no-pie" }, p.tools.clang.getldflags(debug))
		test.contains({ "-fno-PIE", "-no-pie" }, p.tools.clang.getldflags(release))
		test.excludes({ "-fPIE", "-pie" }, p.tools.clang.getldflags(release))
	end

	-- Configuration Default overrides workspace ASLR On.
	function suite.hardenAslr_defaultOverridesWorkspace()
		local prj = aslrProject("gmake", "Linux", "gcc")
		workspace "MyWorkspace"
			hardenaslr "On"
		project "MyProject"
		filter "configurations:Debug"
			hardenaslr "Default"
		local debug = test.getconfig(prj, "Debug")
		local release = p.project.getconfig(debug.project, "Release")
		p.project.validate(debug.project)
		test.excludes({ "-fPIE", "-fPIC", "-pie", "-no-pie", "-fno-PIE" }, p.tools.gcc.getldflags(debug))
		test.contains({ "-fPIE", "-pie" }, p.tools.gcc.getldflags(release))
	end

	-- File Default cannot override configuration ASLR On.
	function suite.hardenAslr_rejectsFileDefaultOverride()
		local prj = aslrProject("ninja", "Linux", "clang")
		files { "main.cpp" }
		hardenaslr "On"
		filter "files:main.cpp"
			hardenaslr "Default"
		checkAslrError(prj, "hardenaslr")
	end
