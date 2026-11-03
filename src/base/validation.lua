---
-- base/validation.lua
--
-- Verify the contents of the project object before handing them off to
-- the action/exporter.
--
-- Copyright (c) 2002-2015 Jess Perkins and the Premake project
---

	local p = premake
	p.validation = {}
	local m = p.validation

	m.elements = {}


---
-- Validate the global container and all of its contents.
---

	m.elements.global = function(glb)
		return {
		}
	end

	function p.global.validate(self)
		p.callArray(m.elements.global, self)
		p.container.validateChildren(self)
	end



---
-- Validate a workspace and its projects.
---

	m.elements.workspace = function(wks)
		return {
			m.workspaceHasConfigs,
			m.uniqueProjectIds,
		}
	end

	function p.workspace.validate(self)
		p.callArray(m.elements.workspace, self)
		p.container.validateChildren(self)
	end



---
-- Validate a project and its configurations.
---

	m.elements.project = function(prj)
		return {
			m.projectHasLanguage,
			m.actionSupportsLanguage,
			m.actionSupportsToolset,
			m.actionSupportsKind,
			m.projectRulesExist,
			m.projectValuesInScope,
		}
	end

	function p.project.validate(self)
		p.callArray(m.elements.project, self)
		for cfg in p.project.eachconfig(self) do
			p.config.validate(cfg)
		end
	end



---
-- Validate a project configuration.
---

	m.elements.config = function(cfg)
		return {
			m.configHasKind,
			m.configSupportsKind,
			m.configValuesInScope,
			m.configHardenAslr,
			m.configHardenAslrFiles,
		}
	end

	function p.config.validate(self)
		p.callArray(m.elements.config, self)

	end



---
-- Validate a rule.
---

	m.elements.rule = function(rule)
		return {
			-- TODO: fill this in
		}
	end

	function p.rule.validate(self)
		p.callArray(m.elements.rule, self)
	end



---
-- Check the values stored in a configuration for values that might have
-- been set out of scope.
--
-- @param container
--    The container being validated; will only check fields which are
--    scoped to this container's class hierarchy.
-- @param expectedScope
--    The expected scope of values in this object, i.e. "project", "config".
--    Values that appear unexpectedly get checked to be sure they match up
--    with the values in the expected scope, and an error is raised if they
--    are not the same.
---

	function p.config.validateScopes(self, container, expected)
		for f in p.field.each() do
			-- If this field scoped to the target container class? If not
			-- I can skip over it (config scope applies to everything).
			local scope
			for i = 1, #f.scopes do
				if f.scopes[i] == "config" or p.container.classIsA(container.class, f.scopes[i]) then
					scope = f.scopes[i]
					break
				end
			end

			local okay = (not scope or scope == "config")

			-- Skip over fields that are at or below my expected scope.
			okay = okay or scope == expected

			-- Skip over fields that bubble up to their parent containers anyway;
			-- these can't be out of scope for that reason
			okay = okay or p.oven.bubbledFields[f.name]

			-- this one needs to checked
			okay = okay or p.field.compare(f, self[scope][f.name], self[f.name])

			-- found a problem?
			if not okay then
				local key = "validate." .. f.name
				p.warnOnce(key, "'%s' on %s '%s' differs from %s '%s'; may be set out of scope", f.name, expected, self.name, scope, self[scope].name)
			end
		end
	end



---------------------------------------------------------------------------
--
-- Handlers for individual checks
--
---------------------------------------------------------------------------

	function m.actionSupportsKind(prj)
		if not p.action.supports(prj.kind) then
			p.warn("Unsupported kind '%s' used for project '%s'", prj.kind, prj.name)
		end
	end


	function m.actionSupportsLanguage(prj)
		if not p.action.supports(prj.language) then
			p.warn("Unsupported language '%s' used for project '%s'", prj.language, prj.name)
		end
	end


	function m.actionSupportsToolset(prj)
		if not p.action.supportsToolset(prj) then
			p.warn("Unsupported toolset '%s' used for language '%s' for project '%s'", prj.toolset, prj.language, prj.name)
		end
	end


	function m.configHasKind(cfg)
		if not cfg.kind then
			p.error("Project '%s' needs a kind in configuration '%s'", cfg.project.name, cfg.name)
		end
	end


	function m.configSupportsKind(cfg)
		if not p.action.supports(cfg.kind) then
			p.warn("Unsupported kind '%s' used in configuration '%s'", cfg.kind, cfg.name)
		end

		-- makefile configuration can only appear in C++ projects; this is the
		-- default now, so should only be a problem if overridden.
		if (cfg.kind == p.MAKEFILE or cfg.kind == p.NONE) and p.project.isdotnet(cfg.project) then
			p.error("Project '%s' uses '%s' kind in configuration '%s'; language must not be C#", cfg.project.name, cfg.kind, cfg.name)
		end
	end


	function m.configValuesInScope(cfg)
		p.config.validateScopes(cfg, cfg.project, "config")
	end


	function m.configHardenAslr(cfg, toolset)
		local prjcfg, filecfg = p.config.normalize(cfg)
		local value = prjcfg.hardenaslr
		if filecfg and cfg.hardenaslr and cfg.hardenaslr ~= value and not (cfg.hardenaslr == "Default" and not value) then
			p.error("hardenaslr cannot differ per file in project '%s' configuration '%s'", prjcfg.project.name, prjcfg.name)
		end
		if value ~= p.ON and value ~= p.OFF then
			return
		end

		local compiler = p.config.toolset(prjcfg) or toolset
		local action = prjcfg.action or _ACTION
		local isVisualStudio = action and action:startswith("vs")
		local usesToolsetFlags = action == "gmake" or action == "ninja" or action == "codelite"
		local supported
		if prjcfg.system == p.LINUX and (not toolset or toolset == p.tools.gcc or toolset == p.tools.clang) then
			supported = (compiler == p.tools.gcc or compiler == p.tools.clang) and (toolset or usesToolsetFlags)
		elseif prjcfg.system == p.WINDOWS then
			if toolset then
				supported = compiler == toolset and (compiler == p.tools.gcc or compiler == p.tools.clang or compiler == p.tools.msc)
			elseif usesToolsetFlags then
				supported = (compiler == p.tools.gcc or compiler == p.tools.clang or compiler == p.tools.msc) and p.action.supportsToolset(prjcfg)
			elseif isVisualStudio then
				supported = (compiler == p.tools.clang or compiler == p.tools.msc) and p.action.supportsToolset(prjcfg)
			end
		end
		if not supported or (prjcfg.language ~= p.C and prjcfg.language ~= p.CPP) or not table.contains({ p.CONSOLEAPP, p.WINDOWEDAPP, p.SHAREDLIB, p.STATICLIB }, prjcfg.kind) then
			p.error("hardenaslr is unsupported for this target, toolset or action in project '%s' configuration '%s'", prjcfg.project.name, prjcfg.name)
		end
		if prjcfg.system == p.LINUX then
			if value == p.OFF and filecfg and cfg.pic and (cfg.pic == p.ON) ~= (prjcfg.pic == p.ON) then
				p.error("hardenaslr code generation cannot differ per file in project '%s' configuration '%s'", prjcfg.project.name, prjcfg.name)
			end
			if value == p.OFF and (prjcfg.kind == p.SHAREDLIB or prjcfg.kind == p.STATICLIB) then
				p.error("hardenaslr Off is unsupported for Linux libraries in project '%s' configuration '%s'", prjcfg.project.name, prjcfg.name)
			end
			if value == p.ON and (cfg.pic or prjcfg.pic) == p.OFF then
				p.error("hardenaslr On conflicts with pic Off in project '%s' configuration '%s'", prjcfg.project.name, prjcfg.name)
			end
		else
			local architecture = prjcfg.architecture
			if architecture and architecture ~= p.X86 and architecture ~= p.X86_64 and architecture ~= p.ARM and architecture ~= p.AARCH64 then
				p.error("hardenaslr is unsupported for architecture '%s' in project '%s' configuration '%s'", architecture, prjcfg.project.name, prjcfg.name)
			end
			if value == p.OFF and (architecture == p.ARM or architecture == p.AARCH64) then
				p.error("hardenaslr Off is unsupported on ARM in project '%s' configuration '%s'", prjcfg.project.name, prjcfg.name)
			end
		end
	end

	function m.configHardenAslrFiles(cfg)
		for _, filename in ipairs(cfg.files) do
			local filecfg = p.fileconfig.getconfig(cfg.project._.files[filename], cfg)
			m.configHardenAslr(filecfg)
		end
	end


	function m.projectHasLanguage(prj)
		if not prj.language then
			p.error("project '%s' does not have a language", prj.name)
		end
	end


	function m.projectRulesExist(prj)
		for i = 1, #prj.rules do
			local rule = prj.rules[i]
			if not p.global.getRule(rule) then
				p.error("project '%s' uses missing rule '%s'", prj.name, rule)
			end
		end
	end


	function m.projectValuesInScope(prj)
		p.config.validateScopes(prj, prj, "project")
	end


	function m.uniqueProjectIds(wks)
		local uuids = {}
		for prj in p.workspace.eachproject(wks) do
			if uuids[prj.uuid] then
				p.error("projects '%s' and '%s' have the same UUID", uuids[prj.uuid], prj.name)
			end
			uuids[prj.uuid] = prj.name
		end
	end


	function m.workspaceHasConfigs(wks)
		if not wks.configurations or #wks.configurations == 0 then
			p.error("workspace '%s' does not contain any configurations", wks.name)
		end
	end
