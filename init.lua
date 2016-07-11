require "preload"

-- bind application hotkeys
hs.fnutils.each({
    { key = "t", app = "iTerm" },
    { key = "b", app = "Google Chrome" },
    { key = "e", app = "Emacs" },
    { key = "s", app = "Slack" }
                }, function(item)

    local appActivation = function()
      hs.application.launchOrFocus(item.app)

      local app = hs.appfinder.appFromName(item.app)
      if app then
        app:activate()
        app:unhide()
      end
    end

    hs.hotkey.bind(hyper, item.key, appActivation)
end)

-- Modal activation / deactivation
modal = hs.hotkey.modal.new({"ctrl", "cmd"}, "space")
mainModalText = "w - windows"
function modal:entered() alert(mainModalText, 999999 ) end
modal:bind("","escape", function() modal:exit() end)
function modal:exited() hs.alert.closeAll() end

modalW = hs.hotkey.modal.new();
modal:bind("","w", function() modalW:enter() end)

winmanText = "hjkl \t\t\t\t jumping\ncmd + hjkl \t halves\nalt + hjkl \t\t increments\nshift + hjkl \t resize\ng \t\t\t\t\t grid\nm \t\t\t\t maximize"

function modalW:entered()
  hs.alert.closeAll()
  alert(winmanText, 999999)
end

modalW:bind("","escape", function() exitModals() end)

function exitModals()
  modalW:exit(); modal:exit()
end

require "window"

hs.alert.show("Config Loaded")


