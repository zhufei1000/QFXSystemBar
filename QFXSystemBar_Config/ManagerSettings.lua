local _, ns = ...
ns = _G.QFXSystemBarNS or ns
local A=ns.ManagerOptionAccess
local definition, refresh, rebuild, contextWidgets
local function T(key) return ns.T and ns.T(key) or key end
local function Disabled(key)
    for _, groups in pairs(ns.OptionDependencies or {}) do
        for _, group in ipairs(groups) do
            for _, child in ipairs(group.children or {}) do
                if child==key and group.enabled and not group.enabled() then return true end
            end
        end
    end
    return false
end
local function Changed(opt,value)
    A.Set(opt,value)
    if refresh then refresh() end
end
local function BuildOrder(s,opt)
    local buttons=opt.type=="buttonOrder"
    local slot=not buttons and A.Slot(opt)
    local order=buttons and A.ButtonOrder() or A.InfoOrder(opt)
    local items, checks={},{}
    for _, value in ipairs(order) do
        local key=value
        local item=buttons and A.ButtonItem(key)
        local label=T(buttons and A.ButtonLabel(item) or A.InfoLabel(key))
        items[#items+1]={key=key,label=label,locked=buttons and key=="Time"}
        checks[#checks+1]={label=label,note=T(buttons and A.ButtonTip(item) or A.InfoTip(key)),
            enabled=function() return not Disabled(opt.key) and not contextWidgets:InCombatLocked() end,
            getValue=function()
                if buttons then return A.DB()[item.var]==true end
                return slot and A.DB()[slot.enabledKey][key]==true or false
            end,
            setValue=function(on)
                if buttons then
                    local function apply(v) A.DB()[item.var]=v; if opt.onChange then opt.onChange() end; if refresh then refresh() end end
                    if item.id=="MeetingStone" and ns.ConfirmMeetingStoneButtonVisibility then
                        ns.ConfirmMeetingStoneButtonVisibility(on,{SetChecked=function(_,v) apply(v) end},apply)
                    else apply(on) end
                elseif slot and ns.SetInfoBarItemEnabled then
                    ns.SetInfoBarItemEnabled(opt.slotKey,key,on)
                    if opt.onChange then opt.onChange() end
                    if refresh then refresh() end
                end
            end}
    end
    s:DragList(items,{disabled=function() return Disabled(opt.key) or contextWidgets:InCombatLocked() end,onChange=function(keys)
        for i,key in ipairs(keys) do
            if buttons then ns.MoveMicroMenuButtonTo(key,i) else ns.MoveInfoBarItemTo(opt.slotKey,key,i) end
        end
        if refresh then refresh() end
    end})
    s:CheckGrid(checks,{columns=2,maxSelected=not buttons and (ns.InfoBarMaxItems or 5) or nil})
end
local function BuildOptions(page,source)
    local s
    for _, value in ipairs(source.options or {}) do
        local opt=value
        if opt.type=="header" then
            if s then page:AddSection(s) end
            s=page:NewSection(A.Name(opt),A.Tip(opt))
        else
            s=s or page:NewSection(T(source.nameKey or source.key))
            local get=function() local v=A.DB()[opt.key]; if v==nil then return opt.default end; return v end
            local set=function(v) Changed(opt,v) end
            local opts={note=A.Tip(opt),getEnabled=function() return not Disabled(opt.key) end,blockInCombat=true}
            if opt.type=="checkbox" then
                s:Check(A.Name(opt),get,set,A.Tip(opt),opts)
            elseif opt.type=="slider" then
                opts.valueSuffix=opt.suffix or opt.unit
                s:ValueSlider(A.Name(opt),opt.min or 0,opt.max or 100,opt.step or 1,get,set,opts)
            elseif opt.type=="dropdown" then
                local entries={}
                for _, entry in ipairs(A.Entries(opt)) do entries[#entries+1]={value=entry.value,text=T(entry.textKey),icon=entry.icon} end
                if opt.searchable then
                    local row=s:Row({type="label",text=A.Name(opt),tooltip=A.Tip(opt)},{type="label",text=""})
                    local items={}
                    for _,entry in ipairs(entries) do items[#items+1]={key=entry.value,label=entry.text,icon=entry.icon} end
                    row._rightRegion._control=contextWidgets:SearchableDropdown(row._rightRegion,190,row:GetFrameLevel(),items,get,set,{
                        maxVisible=opt.maxVisibleRows or 10,menuWidth=280,tooltip=A.Tip(opt),
                        disabled=function() return Disabled(opt.key) end,
                    })
                else
                    s:Dropdown(A.Name(opt),get,set,entries,nil,190,opts)
                end
            elseif opt.type=="color" then
                s:ColorGrid({{label=A.Name(opt),note=A.Tip(opt),
                    getColor=function() return {A.RGB(get())} end,
                    setColor=function(c) set(A.Hex(c[1],c[2],c[3])) end,
                    enabled=opts.getEnabled}},{columns=1})
            elseif opt.type=="buttonOrder" or opt.type=="infoBarContent" then
                BuildOrder(s,opt)
            elseif opt.type=="position" or opt.type=="infoBarPosition" or opt.type=="topCenterWidgetPosition" then
                local render=opt.type=="topCenterWidgetPosition" and A.TopPosition or A.Position
                local _,height=render(s,-s.cursor,opt)
                s.cursor=s.cursor+height
            else
                error("Unsupported system bar option: "..tostring(opt.type))
            end
        end
    end
    if s then page:AddSection(s) end
    local reset=page:NewSection(T("Reset Page"))
    reset:ButtonRow({{text=T("Reset Page"),onClick=function()
        contextWidgets:Confirm({title=T("Reset Page"),text=T("Reset Page"),onAccept=function()
            for _,opt in ipairs(source.options or {}) do A.Reset(opt) end
            definition=nil
            if rebuild then rebuild() end
        end})
    end}, {text=T("Reset All"),onClick=function()
        contextWidgets:Confirm({title=T("Reset All"),text=T("Reset All"),onAccept=function()
            for _,entry in ipairs(ns.OptionPages) do for _,opt in ipairs(entry.options or {}) do A.Reset(opt) end end
            definition=nil
            if rebuild then rebuild() end
        end})
    end}})
    page:AddSection(reset)
end
local originalRefresh=ns.RefreshConfigControls
function ns.RefreshConfigControls(...)
    if originalRefresh then originalRefresh(...) end
    if refresh then refresh() end
end
local originalLocale=ns.RefreshConfigLocalization
function ns.RefreshConfigLocalization(...)
    if originalLocale then originalLocale(...) end
    definition=nil
    if rebuild then rebuild() end
end
local function MakePageTab(config)
    return {key=config.key,titleKey=config.nameKey or config.key,
        prepare=function() A.EnsureInfo(config) end,
        build=function(page) BuildOptions(page,config) end}
end
local function BuildTabs()
    local pagesByKey={}
    for _,page in ipairs(ns.OptionPages or {}) do pagesByKey[page.key]=page end
    local tabs,grouped={},{}
    for _,group in ipairs(ns.OptionGroups or {}) do
        local subtabs={}
        for _,pageKey in ipairs(group.pages or {}) do
            local config=pagesByKey[pageKey]
            if config then subtabs[#subtabs+1]=MakePageTab(config); grouped[pageKey]=true end
        end
        if #subtabs>0 then
            tabs[#tabs+1]={key=group.key,titleKey=group.nameKey or group.key,subtabs=subtabs}
        end
    end
    for _,config in ipairs(ns.OptionPages or {}) do
        if not grouped[config.key] then tabs[#tabs+1]=MakePageTab(config) end
    end
    return tabs
end
function ns.GetManagerSettingsDefinition(context)
    contextWidgets=context.Widgets
    A.DB()
    ns.CloseConfigFrame()
    if not definition then
        definition={external=true,L=T,tabs=BuildTabs()}
        definition.OnTabShow=function(key,_,subKey)
            if ns.TopCenterWidget then ns.TopCenterWidget:SetConfigPageActive((subKey or key)=="topCenterWidget") end
        end
        definition.OnSettingsHide=function()
            refresh,rebuild=nil,nil
            if ns.TopCenterWidget then ns.TopCenterWidget:SetConfigPageActive(false) end
        end
    end
    definition.OnSettingsShow=function() refresh,rebuild=context.Refresh,context.Rebuild end
    return definition
end
