(fn capture [is-note]
  (let [key (if is-note "\"z\"" "")
        current-app (hs.window.focusedWindow)
        pid (.. "\"" (: current-app :pid) "\" ")
        title (.. "\"" (: current-app :title) "\" ")
        run-str  (..
                  "/usr/local/bin/emacsclient"
                  " -c -F '(quote (name . \"capture\"))'"
                  " -e '(spacehammer/activate-capture-frame "
                  pid title key " )'")
        timer (hs.timer.delayed.new .1 (fn [] (io.popen run-str)))]
    (: timer :start)))

;; executes emacsclient, evaluating special function that must be present in
;; Emacs config, passing pid and title of the caller app, along with display id
;; where the screen of the caller app is residing
(fn edit-with-emacs []
  (let [current-app (: (hs.window.focusedWindow) :application)
        pid (.. "\"" (: current-app :pid) "\"")
        title (.. "\"" (: current-app :title) "\"")
        screen (.. "\"" (: (hs.screen.mainScreen) :id) "\"")
        run-str (..
                 "/usr/local/bin/emacsclient"
                 " -c -F '(quote (name . \"edit\"))' "
                 " -e '(spacehammer/edit-with-emacs "
                 pid " " title " " screen " )'")]
    ;; select all + copy
    (hs.eventtap.keyStroke [:cmd] :a)
    (hs.eventtap.keyStroke [:cmd] :c)
    (io.popen run-str)))

;; Don't remove! - this is callable from Emacs
;; See: `spacehammer/edit-with-emacs` in spacehammer.el
(fn edit-with-emacs-callback [pid title screen]
  (let [emacs-app (hs.application.get :Emacs)
        edit-window (: emacs-app :findWindow :edit)
        scr (hs.screen.find (tonumber screen))
        windows (require :windows)]
    (when (and edit-window scr)
      (: edit-window :moveToScreen scr)
      (: windows :center-window-frame))))

;; global keybinging to invoke edit-with-emacs feature
(local edit-with-emacs-key (hs.hotkey.new [:cmd :ctrl] :o nil edit-with-emacs))

(fn run-emacs-fn
  ;; executes given elisp function via emacsclient, if args table present passes
  ;; them to the function
  [elisp-fn args]
  (let [args-lst (when args (.. " '" (table.concat args " '")))
        run-str  (.. "/usr/local/bin/emacsclient"
                     " -e \"(funcall '" elisp-fn
                     (if args-lst args-lst "")
                     ")\"")]
    (io.popen run-str)))

(fn full-screen
  ;; Switch to Emacs and expand its frame to fullscreen
  []
  (hs.application.launchOrFocus :Emacs)
  (run-emacs-fn "(lambda ()) (spacemacs/toggle-fullscreen-frame-on) (spacehammer/fix-frame)"))

(fn vertical-split-with-emacs
  ;; creates a vertical split with the current app and Emacs, with Emacs on the
  ;; left and the app window on the right
  []
  (let [windows    (require :windows)
        cur-app    (-?> (hs.window.focusedWindow) (: :application) (: :name))
        rect-left  [0  0 .5  1]
        rect-right [.5 0 .5  1]
        elisp (.. "(lambda ()"
                  " (spacemacs/toggle-fullscreen-frame-off) "
                  " (spacemacs/maximize-horizontally) "
                  " (spacemacs/maximize-vertically))")]
    (run-emacs-fn elisp)
    (hs.timer.doAfter
     .2
     (fn []
       (if (= cur-app :Emacs)
           (do
             (windows.rect rect-left)
             (windows.jump-to-last-window)
             (windows.rect rect-right))
           (do
             (windows.rect rect-right)
             (hs.application.launchOrFocus :Emacs)
             (windows.rect rect-left)))))))

;; Don't remove! - this is callable from Emacs
;; See: `spacehammer/switch-to-app` in spacehammer.el
(fn switch-to-app [pid]
  (let [app (hs.application.applicationForPID pid)]
    (when app (: app :activate))))

;; Don't remove! - this is callable from Emacs
;; See: `spacehammer/finish-edit-with-emacs` in spacehammer.el
(fn switch-to-app-and-paste-from-clipboard [pid]
  (let [app (hs.application.applicationForPID pid)]
    (when app
      (: app :activate)
      (: app :selectMenuItem [:Edit :Paste]))))

(fn disable-edit-with-emacs []
  (: edit-with-emacs-key :disable))

(fn enable-edit-with-emacs []
  (: edit-with-emacs-key :enable))

(fn maximize
  []
  "
  Maximizes emacs window after 1.5 seconds
  Example in config.fnl to call this function after emacs has been launched.
  "
  (hs.timer.doAfter
   1.5
   (fn []
     (let [app     (hs.application.find :Emacs)
           windows (require :windows)
           modal   (require :modal)]
       (when app
         (: app :activate)
         (windows.maximize-window-frame))))))

{:capture                          capture
 :disable-edit-with-emacs          disable-edit-with-emacs
 :edit-with-emacs                  edit-with-emacs
 :editWithEmacsCallback            edit-with-emacs-callback
 :enable-edit-with-emacs           enable-edit-with-emacs
 :full-screen                      full-screen
 :maximize                         maximize
 :note                             (fn [] (capture true))
 :switchToApp                      switch-to-app
 :switchToAppAndPasteFromClipboard switch-to-app-and-paste-from-clipboard
 :vertical-split-with-emacs        vertical-split-with-emacs}
